package {
    import com.pubnub.PubNubMulti;
    import flash.display.Sprite;
    import flash.utils.setTimeout;

    public class Main extends Sprite {
        private var pubnub:PubNubMulti;

        public function Main() {

            // Setup
            pubnub = new PubNubMulti({
                duplicate_key : "message_id", // Required for PubNubMulti
                subscribe_key : "demo",       // Subscribe Key
                drift_check   : 5000,         // Re-calculate Time Drift
                ssl           : false,        // SSL
                message       : message,      // onMessage Receive
                idle          : idle,         // onPing Idle Message
                connect       : connect,      // onConnect
                reconnect     : reconnect,    // onReconnect
                disconnect    : disconnect    // onDisconnect
            });

            // Add Channels
            pubnub.subscribe({ channels : [ 'b', 'c' ] });

            // Publish Loop
            var pubcount:Number = 1;
            function pub():void {
                setTimeout( pub, 1000 );
                pubnub.publish({ channel : 'b', message : {
                    number : pubcount++,
                    time   : (new Date()).time
                }});
            }
            pub();
        }

        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        // Receive Each Message
        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        private function message(
            message:Object,
            channel:String,
            timetoken:String,
            approx_age:Number
        ):void {
            var age:Number = ((new Date()).time - message.data.time)/2;
            trace('message:',JSON.stringify(message));
            trace('age (ms):',age);
            trace('approx_age (ms):',approx_age);
        }

        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        // Network Connection Established (Ready to Receive)
        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        private function connect():void {
            trace('connected');
        }

        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        // Network Timetoken (Good) Sent by PubNub Upstream
        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        private function idle(timetoken:String):void {
            // trace( 'idle: ', timetoken );
        }

        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        // Disconnected (No Data)
        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        private function disconnect(event:Object):Boolean {
            trace( 'disconnected', event );

            // Resume Connection by Returning - TRUE -
            // By returning false, you can resume by issuing
            // an empty subscribe();
            return true;
        }

        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        // Reconnected (And we are Back!)
        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        private function reconnect():void {
            // trace('reconnected');
        }
    }
}
