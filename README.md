# PubNub Flash SDK

This is a brand new rewrite of the Flash SDK with 
a massive improvement on performance and reliability.

### Full Simple Example

`Main.as` file example follows:

```javascript
package {
    import flash.display.Sprite;
    import com.pubnub.PubNub;

    public class Main extends Sprite {
        public function Main() {

            // Setup
            var pubnub:PubNub = new PubNub({ message : function message(
                message:Object,
                channel:String,
                timetoken:String,
                age:Number
            ):void {
                trace('message:',message);     // Message Payload
                trace('channel:',channel);     // Channel Source
                trace('timetoken:',timetoken); // PubNub TimeToken
                trace('age:',age);             // Aproxmate Age
            } });

            // Add Channels
            pubnub.subscribe({ channels : [ 'a', 'b', 'c' ] });

        }
    }
}
```

More details as follows:


### Import PubNub Client

```javascript
import com.pubnub.PubNub;
```

### Full Init PubNub Client
```javascript
// Setup
var pubnub:PubNub = new PubNub({
    subscribe_key : "demo",              // Subscribe Key
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

