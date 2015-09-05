# tcpdump Remote Counter

This is a two part project the first is a golang server that counts
bandwidth usage and the second is an elm app to display that
count. The server keeps a count of the incoming and outgoing bandwidth
for every host it sees. It will aggregate the received and transmitted
bandwidth for users on the local network and the hosts they hit. This
means you can see if one person is using lots of bandwidth, or if
everyone locally is visiting one service.

The point of this project was originally for me to learn more about
the ELM language. If you have any questions about getting the project
running or why I made certian design decisions, I can be found on
Twitter `@wwkeyboard`.

# Structure

The server serializes the bandwidth counts into a JSON object and
serves it to the Elm client. The server will also serve out everything
in the directory the server is started in. This lets you put an
`index.html` in that directory and use that to interpert and display
the JSON object.

# ToDo

The server and client need to be split into two different projects. I
think the bandwidth counter could be useful on it's own, and has
specific dependencies the Elm client doesn't. It's unfortunate that
the server must be run as sudo to get monitor access to the networking
interface, I have plans to make this able to read a pcap file. My
ideal long term goal is to have tcpdump running in a different process
and pipe that into the server. This would let the server be
distributed as a compiled binary. I don't want to release it as a
binary right now because of the permissions required to get access to
an interface.
