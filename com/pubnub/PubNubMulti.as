package com.pubnub {
    import com.pubnub.PubNub;

    public class PubNubMulti {
        private var connections:Array;
        private var deduplicates:Object;
        private var duplicate_key:String;
        private var origin:String;
        private var message_callback:Function;

        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        // Init
        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        public function PubNubMulti(settings:Object) {
            origin           = settings['origin'] || "ps.pubnub.com";
            message_callback = settings['message'];
            duplicate_key    = settings['duplicate_key'] || "id";

            settings['message'] = multi_message;

            deduplicates = {}
            connections  = [];

            connect( "",                        settings ); // Geo1
            connect( origin,                    settings ); // Geo2
            connect( "pubsub-apac.pubnub.com",  settings ); // Geo3
            connect( "pubsub-emea.pubnub.com",  settings ); // Geo4
            connect( "pubsub-naatl.pubnub.com", settings ); // Geo5
            connect( "pubsub-napac.pubnub.com", settings ); // Geo6
        }
 
        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        // Add Connections
        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        public function connect( origin:String, settings:Object ):void {
            connections.push(new PubNub(settings));
        }

        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        // Receive Each Message and Deduplicate
        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        private function multi_message(
            message:Object,
            channel:String,
            timetoken:String,
            age:Number
        ):void {
            var dkey:String = message[duplicate_key];
            if (dkey in deduplicates) return;
            deduplicates[dkey] = dkey;
            message_callback( message, channel, timetoken, age );
        }

        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        // Add Channels
        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        public function subscribe(settings:Object):void {
            for (var i:Number = 0; connections.length > i; i++) {
                connections[i].subscribe(settings);
            }
        }

        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        // Remove Channels
        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        public function unsubscribe(settings:Object):void {
            for (var i:Number = 0; connections.length > i; i++) {
                connections[i].unsubscribe(settings);
            }
        }

        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        // Publish
        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        public function publish(settings:Object):void {
            // Set Message ID for Deduplication
            settings['message'] = { data : settings['message'] };
            settings['message'][duplicate_key] = PubNub.getUID();

            for (var i:Number = 0; connections.length > i; i++) {
                connections[i].publish(settings);
            }
        }
    }
}
