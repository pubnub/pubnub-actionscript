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
                cipher_key    : 'bt',                // AES256 Crypto Password
                message       : message,             // onMessage Receive
                idle          : idle,                // onPing Idle Message
                connect       : connect,             // onConnect
                reconnect     : reconnect,           // onReconnect
                disconnect    : disconnect           // onDisconnect
            });

            // Add Channels
            pubnub.subscribe({
                channels : [ 'b', 'c' ]
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

        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
        // Network Connection Established (Ready to Receive)
        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
        private function connect():void {
            trace('connected');
        }

        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
        // Network Timetoken (Good) Sent by PubNub Upstream
        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
        private function idle(timetoken:String):void {
            trace( 'idle: ', timetoken );
        }

        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
        // Disconnected (No Data)
        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
        private function disconnect(event:Object):Boolean {
            trace( 'disconnected', event );

            // Resume Connection by Returning - TRUE -
            // By returning false, you can resume by issuing
            // an empty subscribe();
            return true;
        }

        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
        // Reconnected (And we are Back!)
        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
        private function reconnect():void {
            trace('reconnected');
        }
    }
}
