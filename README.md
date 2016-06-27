# WebSockets Serving
This example illustrates how to set up a WebSocket server and handle a connection.

To use the example with Swift Package Manager, type ```swift build``` and then run ``` .build/debug/WebSocketsServer```.

To use the example with Xcode, run the **WebSockets Server** target. This will launch the Perfect HTTP Server. 

Navigate in your web browser to [http://localhost:8181/](http://localhost:8181/)

## Initiating a WebSocket Session

Add one or more URL routes using the `Routing.Routes` subscript functions. These routes will be the endpoints for the WebSocket session. Set the route handler to `WebSocketHandler` and provide your custom closure which will return your own session handler.

The following code is taken from the example project and shows how to enable the system and add a WebSocket handler.

```swift
func addWebSocketsHandler() {
    
    // Add a default route which lets us serve the static index.html file
    Routing.Routes["*"] = { request, response in StaticFileHandler().handleRequest(request: request, response: response) }
    
    // Add the endpoint for the WebSocket example system
    Routing.Routes[.Get, "/echo"] = {
        request, response in
        
        // To add a WebSocket service, set the handler to WebSocketHandler.
        // Provide your closure which will return your service handler.
        WebSocketHandler(handlerProducer: {
            (request: WebRequest, protocols: [String]) -> WebSocketSessionHandler? in
            
            // Check to make sure the client is requesting our "echo" service.
            guard protocols.contains("echo") else {
                return nil
            }
            
            // Return our service handler.
            return EchoHandler()
        }).handleRequest(request: request, response: response)
    }
}
```
## Handling WebSocket Sessions

 A WebSocket service handler must impliment the `WebSocketSessionHandler` protocol.
 This protocol requires the function `handleSession(request: WebRequest, socket: WebSocket)`.
 This function will be called once the WebSocket connection has been established,
 at which point it is safe to begin reading and writing messages.

 The initial `WebRequest` object which instigated the session is provided for reference.
 Messages are transmitted through the provided WebSocket object. 
 Call `WebSocket.sendStringMessage` or `WebSocket.sendBinaryMessage` to send data to the client.
 Call `WebSocket.readStringMessage` or `WebSocket.readBinaryMessage` to read data from the client.
 By default, reading will block indefinitely until a message arrives or a network error occurs.
 A read timeout can be set with `WebSocket.readTimeoutSeconds`.
 When the session is over call `WebSocket.close()`.


The example `EchoHandler` consists of the following.

```swift
class EchoHandler: WebSocketSessionHandler {
	
	// The name of the super-protocol we implement.
	// This is optional, but it should match whatever the client-side WebSocket is initialized with.
	let socketProtocol: String? = "echo"
	
	// This function is called by the WebSocketHandler once the connection has been established.
	func handleSession(request: WebRequest, socket: WebSocket) {
		
		// Read a message from the client as a String.
		// Alternatively we could call `WebSocket.readBytesMessage` to get the data as a String.
		socket.readStringMessage {
			// This callback is provided:
			//	the received data
			//	the message's op-code
			//	a boolean indicating if the message is complete (as opposed to fragmented)
			string, op, fin in
			
			// The data parameter might be nil here if either a timeout or a network error, such as the client disconnecting, occurred.
			// By default there is no timeout.
			guard let string = string else {
				// This block will be executed if, for example, the browser window is closed.
				socket.close()
				return
			}
			
			// Print some information to the console for informational purposes.
			print("Read msg: \(string) op: \(op) fin: \(fin)")
			
			// Echo the data we received back to the client.
			// Pass true for final. This will usually be the case, but WebSockets has the concept of fragmented messages.
			// For example, if one were streaming a large file such as a video, one would pass false for final.
			// This indicates to the receiver that there is more data to come in subsequent messages but that all the data is part of the same logical message.
			// In such a scenario one would pass true for final only on the last bit of the video.
			socket.sendStringMessage(string, final: true) {
				
				// This callback is called once the message has been sent.
				// Recurse to read and echo new message.
				self.handleSession(request, socket: socket)
			}
		}
	}
}
```

## FastCGI Caveat
WebSockets serving is only supported with the stand-alone Perfect HTTP server. At this time, the WebSocket server does not operate with the Perfect FastCGI server.

## Repository Layout

We have finished refactoring Perfect to support Swift Package Manager. The Perfect project has been split up into the following repositories:

* [Perfect](https://github.com/PerfectlySoft/Perfect) - This repository contains the core PerfectLib and will continue to be the main landing point for the project.
* [PerfectTemplate](https://github.com/PerfectlySoft/PerfectTemplate) - A simple starter project which compiles with SPM into a stand-alone executable HTTP server. This repository is ideal for starting on your own Perfect based project.
* [PerfectDocs](https://github.com/PerfectlySoft/PerfectDocs) - Contains all API reference related material.
* [PerfectExamples](https://github.com/PerfectlySoft/PerfectExamples) - All the Perfect example projects and documentation.
* [PerfectEverything](https://github.com/PerfectlySoft/PerfectEverything) - This umbrella repository allows one to pull in all the related Perfect modules in one go, including the servers, examples, database connectors and documentation. This is a great place to start for people wishing to get up to speed with Perfect.
* [PerfectServer](https://github.com/PerfectlySoft/PerfectServer) - Contains the PerfectServer variants, including the stand-alone HTTP and FastCGI servers. Those wishing to do a manual deployment should clone and build from this repository.
* [Perfect-Redis](https://github.com/PerfectlySoft/Perfect-Redis) - Redis database connector.
* [Perfect-SQLite](https://github.com/PerfectlySoft/Perfect-SQLite) - SQLite3 database connector.
* [Perfect-PostgreSQL](https://github.com/PerfectlySoft/Perfect-PostgreSQL) - PostgreSQL database connector.
* [Perfect-MySQL](https://github.com/PerfectlySoft/Perfect-MySQL) - MySQL database connector.
* [Perfect-MongoDB](https://github.com/PerfectlySoft/Perfect-MongoDB) - MongoDB database connector.
* [Perfect-FastCGI-Apache2.4](https://github.com/PerfectlySoft/Perfect-FastCGI-Apache2.4) - Apache 2.4 FastCGI module; required for the Perfect FastCGI server variant.

The database connectors are all stand-alone and can be used outside of the Perfect framework and server.

## Further Information
For more information on the Perfect project, please visit [perfect.org](http://perfect.org).
