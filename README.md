# WebSockets Serving

<p align="center">
    <a href="http://perfect.org/get-involved.html" target="_blank">
        <img src="http://perfect.org/assets/github/perfect_github_2_0_0.jpg" alt="Get Involed with Perfect!" width="854" />
    </a>
</p>

<p align="center">
    <a href="https://github.com/PerfectlySoft/Perfect" target="_blank">
        <img src="http://www.perfect.org/github/Perfect_GH_button_1_Star.jpg" alt="Star Perfect On Github" />
    </a>  
    <a href="http://stackoverflow.com/questions/tagged/perfect" target="_blank">
        <img src="http://www.perfect.org/github/perfect_gh_button_2_SO.jpg" alt="Stack Overflow" />
    </a>  
    <a href="https://twitter.com/perfectlysoft" target="_blank">
        <img src="http://www.perfect.org/github/Perfect_GH_button_3_twit.jpg" alt="Follow Perfect on Twitter" />
    </a>  
    <a href="http://perfect.ly" target="_blank">
        <img src="http://www.perfect.org/github/Perfect_GH_button_4_slack.jpg" alt="Join the Perfect Slack" />
    </a>
</p>

<p align="center">
    <a href="https://developer.apple.com/swift/" target="_blank">
        <img src="https://img.shields.io/badge/Swift-3.0-orange.svg?style=flat" alt="Swift 3.0">
    </a>
    <a href="https://developer.apple.com/swift/" target="_blank">
        <img src="https://img.shields.io/badge/Platforms-OS%20X%20%7C%20Linux%20-lightgray.svg?style=flat" alt="Platforms OS X | Linux">
    </a>
    <a href="http://perfect.org/licensing.html" target="_blank">
        <img src="https://img.shields.io/badge/License-Apache-lightgrey.svg?style=flat" alt="License Apache">
    </a>
    <a href="http://twitter.com/PerfectlySoft" target="_blank">
        <img src="https://img.shields.io/badge/Twitter-@PerfectlySoft-blue.svg?style=flat" alt="PerfectlySoft Twitter">
    </a>
    <a href="http://perfect.ly" target="_blank">
        <img src="http://perfect.ly/badge.svg" alt="Slack Status">
    </a>
</p>

This example illustrates how to set up a WebSocket server and handle a connection.

To use the example with Swift Package Manager, type ```swift build``` and then run ``` .build/debug/WebSocketsServer```.

To use the example with Xcode, run the **WebSockets Server** target. This will launch the Perfect HTTP Server. 

Navigate in your web browser to [http://localhost:8181/](http://localhost:8181/)

## Issues

We are transitioning to using JIRA for all bugs and support related issues, therefore the GitHub issues has been disabled.

If you find a mistake, bug, or any other helpful suggestion you'd like to make on the docs please head over to [http://jira.perfect.org:8080/servicedesk/customer/portal/1](http://jira.perfect.org:8080/servicedesk/customer/portal/1) and raise it.

A comprehensive list of open issues can be found at [http://jira.perfect.org:8080/projects/ISS/issues](http://jira.perfect.org:8080/projects/ISS/issues)

## Initiating a WebSocket Session

Add one or more URL routes using the `Routing.Routes` subscript functions. These routes will be the endpoints for the WebSocket session. Set the route handler to `WebSocketHandler` and provide your custom closure which will return your own session handler.

The following code is taken from the example project and shows how to enable the system and add a WebSocket handler.

```swift
func makeRoutes() -> Routes {
	
	var routes = Routes()
    // Add a default route which lets us serve the static index.html file
	routes.add(method: .get, uri: "*", handler: { request, response in
		StaticFileHandler(documentRoot: request.documentRoot).handleRequest(request: request, response: response)
	})
    
    // Add the endpoint for the WebSocket example system
	routes.add(method: .get, uri: "/echo", handler: {
        request, response in
        
        // To add a WebSocket service, set the handler to WebSocketHandler.
        // Provide your closure which will return your service handler.
        WebSocketHandler(handlerProducer: {
            (request: HTTPRequest, protocols: [String]) -> WebSocketSessionHandler? in
            
            // Check to make sure the client is requesting our "echo" service.
            guard protocols.contains("echo") else {
                return nil
            }
            
            // Return our service handler.
            return EchoHandler()
        }).handleRequest(request: request, response: response)
    })
	
	return routes
}
```
## Handling WebSocket Sessions

 A WebSocket service handler must impliment the `WebSocketSessionHandler` protocol.
 This protocol requires the function `handleSession(request: HTTPRequest, socket: WebSocket)`.
 This function will be called once the WebSocket connection has been established,
 at which point it is safe to begin reading and writing messages.

 The initial `HTTPRequest` object which instigated the session is provided for reference.
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
	func handleSession(request: HTTPRequest, socket: WebSocket) {
		
		// Read a message from the client as a String.
		// Alternatively we could call `WebSocket.readBytesMessage` to get binary data from the client.
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
			socket.sendStringMessage(string: string, final: true) {
				
				// This callback is called once the message has been sent.
				// Recurse to read and echo new message.
				self.handleSession(request: request, socket: socket)
			}
		}
	}
}
```

## FastCGI Caveat
WebSockets serving is only supported with the stand-alone Perfect HTTP server. At this time, the WebSocket server does not operate with the Perfect FastCGI server.



## Further Information
For more information on the Perfect project, please visit [perfect.org](http://perfect.org).
