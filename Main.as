package {
    import com.pubnub.PubNub;
    import flash.display.Sprite;
    import flash.utils.setTimeout;

    public class Main extends Sprite {
        private var pubnub:PubNub;

        public function Main() {

            // Setup
            pubnub = new PubNub({
                subscribe_key : "demo",
                drift_check   : 5000,        // Re-calculate Time Drift
                ssl           : false,       // SSL
                message       : message,     // onMessage Receive
                idle          : idle,        // onPing Idle Message
                connect       : connect,     // onConnect
                reconnect     : reconnect,   // onReconnect
                disconnect    : disconnect   // onDisconnect
            });

            // Add Channels
            pubnub.subscribe({ channels : [ 'a', 'b', 'c' ] });
        }

        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        // Receive Each Message
        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        private function message(
            message:Object,
            channel:String,
            timetoken:String,
            age:Number
        ):void {
            trace('message:',message);
            trace('age:',age);
        }

        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        // Network Connection Established (Ready to Receive)
        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        private function connect():void {
            trace('connected');
            trace('publishing...');
            pubnub.publish({
                channel  : 'b',
                message  : 'Hello!',
                response : function(r:Object):void {
                    trace('publish:',r);
                    trace('unsubscribing soon...');
                    setTimeout( unsub, 1000 );
                }
            });

            // Unsubscribing
            function unsub():void {
                trace('Unsubscribed!');
                pubnub.unsubscribe({ channels : [ 'a', 'b', 'c' ] });
                setTimeout( sub, 2500 );
            }

            // Subscribing
            function sub():void {
                trace('Subscribed!');
                pubnub.subscribe({ channels : [ 'a', 'b', 'c' ] });
                //setTimeout( unsub, 2500 );
            }
        }

        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        // Network Timetoken (Good) Sent by PubNub Upstream
        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        private function idle(timetoken:String):void {
            trace( 'idle: ', timetoken );
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
            trace('reconnected');
        }
    }
}
