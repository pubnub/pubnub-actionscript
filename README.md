# PubNub Flash SDK

This is a brand new rewrite of the Flash SDK with 
a massive improvement on performance and reliability.

### Full Simple Example

```javascript
package {
    import flash.display.Sprite;
    import com.pubnub.PubNub;

    public class Main extends Sprite {
        public function Main() {
            // Setup
            var pubnub:PubNub = new PubNub({
                subscribe_key : "demo",
                origin        : "pubsub.pubnub.com", // GeoDNS Global PubNub
                ssl           : false,               // SSL ?
                message       : message
            });

            // Add Channels
            pubnub.subscribe({
                channels : [ 'a', 'b', 'c' ]
            });
        }

        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
        // Receive Each Message
        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
        private function message(
            message:Object,
            channel:String,
            timetoken:String,
            latency:Number
        ):void {
            trace('message:',message);
            trace('latency:',latency);
        }
    }
}
```

More details as follows:


### Import PubNub Client

```javascript
import com.pubnub.PubNub;
```

### Fully Initalize PubNub Client
```javascript
// Setup
var pubnub:PubNub = new PubNub({
    subscribe_key : "demo",
    origin        : "pubsub.pubnub.com", // GeoDNS Global PubNub
    ssl           : false,               // SSL ?
    cipher_key    : 'mypass',            // AES256 Crypto Password
    message       : message,             // onMessage Receive
    idle          : idle,                // onPing Idle Message
    connect       : connect,             // onConnect
    reconnect     : reconnect,           // onReconnect
    disconnect    : disconnect           // onDisconnect
});
```

### Add Channels
```javascript
pubnub.subscribe({ channels : [ 'b', 'c' ] });
```

