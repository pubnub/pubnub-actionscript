package {
    //import com.pubnub.PubNubMultiGeo;
	import com.pubnub.PubNubMultiGeo;
    import flash.display.Sprite;
    import flash.utils.setTimeout;

    public class Main extends Sprite {
        private var pubnub:PubNubMultiGeo;

        public function Main() {

            // Setup
            pubnub = new PubNubMultiGeo({
                message_id    : "message_id", // Required for PubNubMultiGeo
                subscribe_key : "demo",       // Subscribe Key
                drift_check   : 9000,         // Re-calculate Time Drift
                ssl           : true,         // SSL
                analytics     : 'analytics',  // Channel to Save Analytic on
                error         : error,        // onErrors
                activity      : activity,     // onAny Activity
                message       : message,      // onMessage Receive
                idle          : idle,         // onPing Idle Message
                connect       : connect,      // onConnect
                reconnect     : reconnect,    // onReconnect
                disconnect    : disconnect    // onDisconnect
            });

            // Add Channels
            pubnub.subscribe({ channels : [ 'bob', 'cat' ] });

            // Publish Loop
            var pubcount:Number = 1;
            function pub():void {
                setTimeout( pub, 1000 );
                pubnub.publish({ channel : 'bob', message : {
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
            approx_age:Number,
			origin:String
        ):void {
            trace('message:',JSON.stringify(message));
			trace('origin:',origin);
            trace('approx_age (ms):',approx_age);
        }

        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        // Network Connection Established (Ready to Receive)
        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        private function connect():void {
            trace('connected');
        }

        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        // All Network Activity
        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        private function activity(url:String):void {
            trace( 'activity: ', url );
        }

        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        // Network Timetoken (Good) Sent by PubNub Upstream
        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        private function idle(timetoken:String):void {
            // trace( 'idle: ', timetoken );
        }

        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        // Error Details
        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        private function error(reason:String):void {
            trace( 'ERROR', reason );
        }

        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        // Disconnected (No Data)
        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        private function disconnect(event:Object):void {
            trace( 'DISCONNECTED!!!!!!!!!', event );
        }

        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        // Reconnected (And we are Back!)
        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        private function reconnect():void {
            // trace('reconnected');
        }
    }
}
