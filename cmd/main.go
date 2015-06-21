package main

import (
	"flag"
	"fmt"
	"log"
	"net/http"
	"regexp"

	"code.google.com/p/gopacket"
	"code.google.com/p/gopacket/pcap"
)

type PacketCount struct {
	src  string
	dst  string
	size uint64
}

var (
	re = regexp.MustCompile("[0-9]+|\n|\t")

	goingChan = make(chan *PacketCount, 100)

	outgoingBytes = map[string]uint64{}
	incomingBytes = map[string]uint64{}
)

func main() {
	// var (
	// 	device  = flag.String("device", "en0", "device to listen to")
	// 	timeout = flag.Duration("timeout", pcap.BlockForever, "time intervals to parse captured packets")
	// )
	flag.Parse()

	const (
		MTULen          = 1500
		promiscuousMode = true
	)

	//handle, err := pcap.OpenLive(*device, MTULen, promiscuousMode, *timeout)
	handle, err := pcap.OpenOffline("./dump_one.pcap")
	if err != nil {
		log.Fatalln(err)
	}

	packetSource := gopacket.NewPacketSource(handle, handle.LinkType())

	go countBytes(goingChan)

	go func() {
		for packet := range packetSource.Packets() {
			go handlePacket(packet, goingChan)
		}
	}()

	http.HandleFunc("/count", showClientMap)
	http.Handle("/", http.FileServer(http.Dir("./")))

	if err := http.ListenAndServe(":8080", nil); err != nil {
		log.Fatalln(err)
	}
}

func showClientMap(w http.ResponseWriter, r *http.Request) {
	fmt.Println("Received request")
	fmt.Fprint(w, `{"hosts": [`)
	cnt := len(outgoingBytes)
	for k, v := range outgoingBytes {
		fmt.Fprintf(w, "\n { \"ip_address\": %q, \"outgoing\": %v }", k, v)
		if cnt > 1 {
			fmt.Fprint(w, ",")
		}
		cnt--
	}
	fmt.Fprint(w, `] }`)
}

func handlePacket(packet gopacket.Packet, counter chan *PacketCount) {
	appLayer := packet.ApplicationLayer()
	if appLayer == nil {
		return
	}

	if networkLayer := packet.NetworkLayer(); networkLayer != nil {
		srcIP := networkLayer.NetworkFlow().Src().String()
		dstIP := networkLayer.NetworkFlow().Dst().String()

		meta := packet.Metadata()
		counter <- &PacketCount{
			src:  srcIP,
			dst:  dstIP,
			size: uint64(meta.Length),
		}
	}
}

func countBytes(queue chan *PacketCount) {
	for r := range queue {
		outgoingBytes[r.src] += r.size
		outgoingBytes["total"] += r.size

		incomingBytes[r.dst] += r.size
		incomingBytes["total"] += r.size
	}
}
