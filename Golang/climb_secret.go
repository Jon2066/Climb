package main

import (
	"crypto/rand"
	"encoding/json"
	"encoding/binary"
	"encoding/hex"
	"errors"
	"fmt"
	"bytes"
	"math/big"
	"io/ioutil"
	"log"
	"net"
	"io"
	"net/url"
	"strings"
	"github.com/forgoer/openssl"
	"github.com/wenzhenxi/gorsa"
)

type User struct {
	username string
	password string
}

type Config struct {
	client_pub     string
	server_private string
	server_port    string
	users          []User
}

func (c *Config) chekUser(user string, password string) (err error) {
	for _, aUser := range c.users {
		if aUser.username == user && aUser.password == password {
			return nil
		}
	}
	return errors.New("用户名或密码错误401")
}

func (c *Config) loadFromJson() {
	data, _ := ioutil.ReadFile("./climb_config.json")
	var v map[string]interface{}
	json.Unmarshal(data, &v)
	//新手 json转结构体转不出来？？手动解析吧 囧
	c.client_pub = v["client_pub"].(string)
	c.server_private = v["server_private"].(string)
	c.server_port = v["server_port"].(string)
	c.users = []User{}
	users := v["users"].([]interface{})
	for _, aUser := range users {
		aUser := aUser.(map[string]interface{})
		username := aUser["username"].(string)
		password := aUser["password"].(string)
		c.users = append(c.users, User{username, password})
	}
}

var config Config = Config{}

func main() {
	config.loadFromJson()
	log.SetFlags(log.LstdFlags | log.Lshortfile)
	l, err := net.Listen("tcp", ":"+config.server_port)
	if err != nil {
		log.Panic(err)
	}

	for {
		client, err := l.Accept()
		if err != nil {
			log.Panic(err)
		}

		go handleClientRequest(client)
	}
}

func handleClientRequest(client net.Conn) {
	if client == nil {
		return
	}

	var rbString string = ""
	for{
			 buf := make([]byte, 4096)
			 n, err := client.Read(buf)
			 if err != nil && err != io.EOF{
				 fmt.Println("❌客户端接收返回错误" + err.Error())
				 return   // 收到错误返回
			 }
			 if err == io.EOF { //空数据直接写
					break
				}else{
					bufString := string(buf[:n])
					rbString = rbString + bufString
					if strings.Index(bufString, "#") != -1{
						break;
					}
				}
	 }
	 // fmt.Println("收到客户端请求" + rbString)
	n := strings.Index(rbString, "#")
	if  n == -1 {
		fmt.Println("❌收到客户端请求格式不正确"+ rbString)
		return
	}
	data, err := decryptReceiveData([]byte(rbString[0:n]))
	if err != nil{
		fmt.Println("❌收到客户端请求解密失败" + err.Error())
		backMsg :=  "HTTP/1.1 407 Connection established\r\n\r\n"
		enData, _ := encryptData([]byte(backMsg))
		fmt.Fprint(client, string(enData))
		return
	}
	var method, requestUrl, address string
	fmt.Sscanf(string(data), "%s%s", &method, &requestUrl)
	if strings.Index(requestUrl, "://") == -1 {
		if strings.Index(requestUrl, ":443") != -1 {
			requestUrl = "https://" + requestUrl
		} else {
			requestUrl = "http://" + requestUrl
		}
	}
	hostPortURL, err := url.Parse(requestUrl)
	if err != nil {
		log.Println(err)
		return
	}
	if hostPortURL.Opaque != "" { //https访问
		address = hostPortURL.Scheme + ":" + hostPortURL.Opaque
	} else { //http访问
		if strings.Index(hostPortURL.Host, ":") == -1 { //host不带端口， 默认80
			address = hostPortURL.Host + ":80"
		} else {
			address = hostPortURL.Host
		}
	}
	// fmt.Println("发起TCP 请求 " + address)
	//获得了请求的host和port，就开始拨号吧
	server, err := net.Dial("tcp", address)
	if err != nil {
		log.Println("连接远程服务失败" + err.Error())
		return
	}
	if method == "CONNECT" {
		backMsg :=  "HTTP/1.1 200 Connection established\r\n\r\n"
		enData, err := encryptData([]byte(backMsg))
		if err != nil {
			// fmt.Println(err)
			return
		}
		fmt.Fprint(client, string(enData))
	} else {
		// fmt.Println("向服务端写数据")
		server.Write(data)
	}
	go readDataFromClient(server, client)
	readDataFromServer(server, client)
}

func readDataFromClient(server net.Conn, client net.Conn)  {
	var intact string = ""
	for{
       buf := make([]byte, 1024 * 8)
       n, err := client.Read(buf)
       if err != nil && err != io.EOF{
				 fmt.Println("❌客户端接收数据返回错误" + err.Error())
           break
       }
			 if err == io.EOF {
		 		// fmt.Println("❌从客户端接收到EOF")
		 		// server.Write(buf[:n])
				break
		 	}else{
		 		checkClientIntactDataAndSend(buf[:n], &intact, server)
		 	}
   }
	 client.Close()
}

// 从客户端发来数据后  找到一条完整加密数据 解密后转发到服务端
func checkClientIntactDataAndSend(buf []byte, intact *string, server net.Conn)  {
		bufString := string(buf)
		index := strings.Index(bufString, "#")
		if index != -1 {
			 //拿到一条完整加密数据 发送过来以#作为结尾
			 *intact = *intact + bufString[:index]
 			 deData, err	:= decryptReceiveData([]byte(*intact))
			 if err != nil {
				 fmt.Println("❌从客户端读数据 解密错误" + err.Error())
			 }else {
					 // fmt.Println("向真正服务端发数据")
					 // fmt.Println(string(deData))
					 server.Write(deData)
			 }
			 //赋值为空 获取下一条完整加密数据
			 *intact = ""
			 if index == len(bufString) - 1 { //如果已经匹配到最后 直接返回
			 		return
			 }else{
				 //递归 从剩下的数据中再次寻找完整数据
				 checkClientIntactDataAndSend([]byte(bufString[index+1:]), intact, server)
			 }
		 }else{
			 //没有匹配到一条完整加密数据 数据都赋值给intact 等待下一次接收数据
			 *intact = *intact + bufString
		 }
}


func readDataFromServer(server net.Conn, client net.Conn)  {
	for{
     buf := make([]byte, 1024 * 8)
     n, err := server.Read(buf)
		 if err != nil && err != io.EOF{
			 	fmt.Println("❌服务端返回错误" + err.Error())
        break
     }
		 if err == io.EOF {
			// fmt.Println("❌从服务端接收到EOF")
				break
		}
		 // fmt.Println("从真正服务端读数据" + string(buf[:n]))
		 enData, err	:= encryptData(buf[:n])
		 if err != nil {
	 			fmt.Println("❌加密错误")
	 			fmt.Println(err)
	 		}else {
	 			// fmt.Println("加密数据后发回客户端" + string(enData))
	 			client.Write(enData)
	 		}
  }
	server.Close()
}

func decryptReceiveData(data []byte) (requestData []byte, fb error) {
	var v map[string]string
  err := json.Unmarshal(data, &v)
	if err != nil {
		fmt.Println("❌传入数据json解析错误 :" + string(data))
		return []byte{}, err
	}
	var key string = v["k"]
	rsaKey, err := gorsa.PriKeyDecrypt(key,config.server_private)
	if err != nil {
		return []byte{}, err
	}
	kv := strings.Split(rsaKey, "|")
	var aesString string = v["v"]
	dataByte, err := hex.DecodeString(aesString)
	if err != nil {
		return []byte{}, err
	}
	// 格式 AES|CBC|key|iv
	// 目前只有 AES-CBC 和 AES-ECB
	if len(kv) == 4 {
		var aesKey string = kv[2]
		var iv string = kv[3]
		decryptData, err := openssl.AesCBCDecrypt(dataByte, []byte(aesKey), []byte(iv), openssl.PKCS7_PADDING)
		if err != nil {
			return []byte{}, err
		}
		return checkUserAndGetRequestData(string(decryptData))
	}else{
		var aesKey string = kv[2]
		decryptData, err := openssl.AesECBDecrypt(dataByte, []byte(aesKey),openssl.PKCS7_PADDING)
		if err != nil {
			return []byte{}, err
		}
		return checkUserAndGetRequestData(string(decryptData))
	}
}

func checkUserAndGetRequestData(data string) (requestData []byte, err error) {
	var v map[string]string
	dataByte := []byte(data)
	jsonErr := json.Unmarshal(dataByte, &v)
	if jsonErr != nil {
		return []byte{}, jsonErr
	}
	username := v["username"]
	password := v["password"]
	authErr := config.chekUser(username, password)
	if authErr != nil {
		return []byte{}, authErr
	}
	hexString :=v["data"]
	vData, err := hex.DecodeString(hexString)
	// fmt.Println("解密后客户端发来的原数据" + string(vData))
	if err != nil {
		return []byte{}, err
	}
	return vData, nil
}

// RandString 生成随机字符串
func RandString(len int) string {
	var container string
    var str = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890"
    b := bytes.NewBufferString(str)
    length := b.Len()
    bigInt := big.NewInt(int64(length))
    for i := 0;i < len ;i++  {
        randomInt,_ := rand.Int(rand.Reader,bigInt)
        container += string(str[randomInt.Int64()])
    }
    return container
}

func encryptData(data []byte) (enData []byte, err error) {
		var keyType = "AES|ECB"
		var n int32
		binary.Read(rand.Reader, binary.LittleEndian, &n)
		index := n % 3
		var iv string = ""
		var key string = RandString(32)
		if(index == 0){
			key = RandString(16)
		} else if index == 1 {
			key = RandString(24)
		}
		var t int32
		binary.Read(rand.Reader, binary.LittleEndian, &t)

		if t % 2 == 0 {
			keyType = "AES|CBC"
			iv = RandString(16)
		}

		var kString string = keyType + "|" + key
		if  iv != "" {
			kString = kString + "|" + iv
		}
		//RSA 加密key
		kString, err = gorsa.PublicEncrypt(kString, config.client_pub)
		if err != nil{
			return []byte{}, err
		}
		dataDic := map[string]string{}
		dataDicHex := hex.EncodeToString(data)
		dataDic["data"] = dataDicHex

		dData, err := json.Marshal(dataDic)
		var aesData []byte
		if iv == "" {
			aesData, err= openssl.AesECBEncrypt(dData, []byte(key), openssl.PKCS7_PADDING)
			if err != nil{
				return []byte{}, err
			}
		}else{
			aesData, err = openssl.AesCBCEncrypt(dData, []byte(key), []byte(iv),  openssl.PKCS7_PADDING)
			if err != nil{
				return []byte{}, err
			}
		}
		result := map[string]string{}
		result["k"] = kString
		result["v"] = hex.EncodeToString(aesData)

		jsonData, err := json.Marshal(result)
		if err != nil{
			return []byte{}, err
		}
		jsonString := string(jsonData)
		jsonString = jsonString + "#"
		return  []byte(jsonString), nil
}
