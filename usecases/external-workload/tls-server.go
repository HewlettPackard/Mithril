package main

import (
	"crypto/tls"
	"crypto/x509"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"os"
)

var (
	serverCertPath string = os.Getenv("SERVER_CERT_PATH")
	serverKeyPath  string = os.Getenv("SERVER_KEY_PATH")
	caBundlePath   string = os.Getenv("CA_BUNDLE_PATH")
)

func main() {
	mux := http.NewServeMux()
	mux.HandleFunc("/", func(w http.ResponseWriter, req *http.Request) {
		println("Received request.")
		w.Header().Add("Strict-Transport-Security", "max-age=63072000; includeSubDomains")
		for name, headers := range req.Header {
			for _, h := range headers {
				fmt.Fprintf(w, "%v: %v\n", name, h)
			}
		}
		w.Write([]byte("Request TLS state:\n"))
		fmt.Fprintf(w, "%+v", req.TLS)
	})

	if serverCertPath == "" || serverKeyPath == "" || caBundlePath == "" {
		panic("SERVER_CERT_PATH, SERVER_KEY_PATH or CA_BUNDLE_PATH not set")
	}

	cer, err := tls.LoadX509KeyPair(serverCertPath, serverKeyPath)
	if err != nil {
		log.Println(err)
		return
	}

	root, err := ioutil.ReadFile(caBundlePath)
	if err != nil {
		panic(fmt.Errorf("Failed to load certificates %v", err))
	}

	cp := x509.NewCertPool()
	if !cp.AppendCertsFromPEM(root) {
		panic(fmt.Errorf("Failed to append certificates"))
	}

	cfg := &tls.Config{
		Certificates:       []tls.Certificate{cer},
		RootCAs:            cp,
		InsecureSkipVerify: true,
	}

	srv := &http.Server{
		Addr:         ":9443",
		Handler:      mux,
		TLSConfig:    cfg,
		TLSNextProto: make(map[string]func(*http.Server, *tls.Conn, http.Handler), 0),
	}

	fmt.Println("Starting server...")

	log.Fatal(srv.ListenAndServeTLS(serverCertPath, serverKeyPath))
}
