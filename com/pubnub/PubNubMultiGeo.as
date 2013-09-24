package com.pubnub {
    import com.pubnub.PubNub;
    import flash.utils.setTimeout;

    public class PubNubMultiGeo {
        private var analytics_sync:PubNub;  // Tracking Reporter
        private var analytics:Object;       // Tracking Data Object
        private var connections:Array;      // Connection Pool to Geo Regions
        private var deduplicates:Object;    // Deduplication Buffer
        private var deduplicates_la:Array;  // Deduplication Buffer Laundry
        private var duplicate_key:String;   // Inique Message ID
        private var origin:String;          // Primary Origin
        private var msg_callback:Function;  // User Callback for Messages

        private static const DUP_KEY_MAX_AGE:Number = 30 * 60 * 1000;

        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        // Init
        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        public function PubNubMultiGeo(settings:Object) {
            origin        = settings['origin'] || "ps.pubnub.com";
            msg_callback  = settings['message'];
            duplicate_key = settings['duplicate_key'] || "id";

            settings['message'] = multi_message;

            deduplicates    = {};
            deduplicates_la = [];
            connections     = [];

            // First Geo
            connect( "", settings );

            // Prevent Multi-callbacks
            settings['idle']       = function():void{};
            settings['connect']    = function():void{};
            settings['disconnect'] = function():void{};
            settings['reconnect']  = function():void{};

            // Connect to a few other Geo's
            connect( origin,                    settings ); // Geo2
            connect( "pubsub-apac.pubnub.com",  settings ); // Geo3
            connect( "pubsub-emea.pubnub.com",  settings ); // Geo4
            connect( "pubsub-naatl.pubnub.com", settings ); // Geo5
            connect( "pubsub-napac.pubnub.com", settings ); // Geo6

            // Setup PubNub Analytics Tracking Broadcaster
            analytics_sync = new PubNub({
                publish_key   : '109bef91-c638-4d6b-a7f6-18f367631b42',
                subscribe_key : '0ce6d447-bf92-11df-8142-332cdc753f0e'
            });

            // Set Cleanup Buffer Loop
            cleanup_dup_buffer();
        }
 
        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        // Setup and Track Analaytics
        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        private function setup_tracking():void {
            // on message receive, trigger a timeer to fire to push the
            // -
            // TODO - per signal id "duplicate_key" store following
            // TODO - local_time_first arrived mesage
            // TODO - last_arrived arrived mesage
            // TODO - Local Time.
            // TODO - Drift Time.
            // TODO - TimeToken TX.
            // TODO - TimeToken TR.
            // TODO - Data Center Origin.
            // TODO - Aggregated Total of Messages Received and Expected.
            // TODO - List of Aprox. Ages.
            // TODO - Duplicate ID Val ("signal_id").
            // TODO - 
            // TODO - 
            // TODO - 
            // TODO - 
            // TODO - 

        }

        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        // Track Analaytics
        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        private function track(data:Object):void {
            var message    = data['message']
            ,   message_id = message[duplicate_key];

            /*
            analytics['46573654'].local_time = 13467768544;
                 : {
                    local_time : now(),
                    drift      : analytics_sync
                }
            };
            */
        }
 
        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        // Add Connections
        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        public function connect( origin:String, settings:Object ):void {
            settings['origin'] = origin;
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
            var message_id:String = message[duplicate_key];
            if (message_id in deduplicates) return;

            // Catch Message ID and Mark for cleanup at future.
            deduplicates[message_id] = 1;
            deduplicates_la.push({
                message_id : message_id,
                time       : now()
            });

            msg_callback( message, channel, timetoken, age );
        }

        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        // Cleanup Deduplication Buffer
        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        public function cleanup_dup_buffer():void {
            var max_age:Number = DUP_KEY_MAX_AGE;

            // Call Cleanup Again
            setTimeout( cleanup_dup_buffer, max_age - 1000 );

            // Test Duplicate Age
            while (
                deduplicates_la.length &&
                deduplicates_la[0].time + max_age < now()
            ) {
                trace( 'cleaining: ', deduplicates_la[0].message_id );
                delete deduplicates[deduplicates_la.shift().message_id];
            }
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

        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        // Now Utility
        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        public function now():Number {
            return (new Date()).time;
        }
    }
}
