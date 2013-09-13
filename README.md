# PubNub Flash SDK

This is a brand new rewrite of the Flash SDK with 
a massive improvement on performance and reliability.

### Simple Example

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

### Import PubNub Client

```javascript
import com.pubnub.PubNub;
```

### Full Init PubNub Client

To see full usage example, visit the `Main.as` file.

```javascript
var pubnub:PubNub = new PubNub({
    publish_key   : "demo",              // Publish Key
    subscribe_key : "demo",              // Subscribe Key
    drift_check   : 60000,               // Re-calculate Time Drift (ms)
    ssl           : false,               // SSL ?
    cipher_key    : 'mypass',            // AES256 Crypto Password
    message       : message,             // onMessage Receive
    idle          : idle,                // onPing Idle
    connect       : connect,             // onConnect
    reconnect     : reconnect,           // onReconnect
    disconnect    : disconnect           // onDisconnect
});
```

### Add Channels
```javascript
pubnub.subscribe({ channels : [ 'b', 'c' ] });
```

### Remove Channels
```javascript
pubnub.unsubscribe({ channels : [ 'b', 'c' ] });
```

### Publish Message
```javascript
pubnub.publish({
    channel  : 'b',
    message  : 'Hello!',
    response : function(r:Object):void {
        trace('publish:',JSON.stringify(r));
    }
});
```
