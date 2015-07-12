# glowing-pcap-bear

The point of this project is for me to learn more about the ELM language. You shouldn't consider it production ready, idiomatic, or really anything other than a neat toy. If you want to talk more about this neat toy, I can be found on twitter `@wwkeyboard`.

There are two parts of this project. A server that monitors one interface and counts the bandwidth between hosts. This server serializes that bandwidth count into a JSON object and serves it. The server will also serve out everything in the directory the server is started in. This lets you put an `index.html` in that directory and use that to interpert and display the JSON object.

The second part of this project is an ELM app that polls the server and displays the results. It's very much a work-in-progress.
