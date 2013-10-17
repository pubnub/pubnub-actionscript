package com.pubnub {
    import com.pubnub.PubNub;
    import flash.utils.setTimeout;

    public class PubNubMultiGeo {
        private var analytics:Object;          // Tracking Data Object
        private var analytics_sync:PubNub;     // Tracking Reporter
        private var analytics_channel:String;  // Channel to Save Analytics on
        private var analytics_session:String;  // Session ID for Tracking
        private var callbacks:Object;          // Callbacks References
        private var connections:Array;         // Connection Pool GeoRegions
        private var deduplicates:Object;       // Deduplication Buffer
        private var deduplicates_la:Array;     // Deduplication Buffer Laundry
        private var duplicate_key:String;      // Inique Message ID
        private var origin:String;             // Primary Origin
        private var msg_callback:Function;     // User Callback for Messages

        private static const DUP_KEY_MAX_AGE:Number = 30 * 60 * 1000; // 30min

        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        // Init
        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        public function PubNubMultiGeo(settings:Object) {
            origin        = settings['origin'] || "ps.pubnub.com";
            msg_callback  = settings['message'];
            duplicate_key = settings['duplicate_key'] ||
                            settings['message_id']    || "id";

            // Some Variable Goodness
            callbacks       = {};
            analytics       = {};
            deduplicates    = {};
            deduplicates_la = [];
            connections     = [];

            // Callbacks
            settings['message'] = multi_message;
            callbacks['error']  = settings['error'] || PubNub.fun();

            // Set Analytics Channel to Track Delivery Metrics
            analytics_channel = settings['analytics'] || 'analytics';
            analytics_session = PubNub.getUID();

            // Geo1 - Connect to a few other Geo's
            connect( "", settings );

            // Prevent Multi-callbacks
            settings['idle']       = function():void{};
            settings['error']      = function():void{};
            settings['connect']    = function():void{};
            settings['disconnect'] = function():void{};
            settings['reconnect']  = function():void{};

            // connect( origin,                    settings ); // Geo2
            // connect( "pubsub-apac.pubnub.com",  settings ); // Geo3
            // connect( "pubsub-emea.pubnub.com",  settings ); // Geo4
            connect( "pubsub-naatl.pubnub.com", settings );    // Geo5
            connect( "pubsub-napac.pubnub.com", settings );    // Geo6

            // Setup PubNub Analytics Tracking Broadcaster
            analytics_sync = new PubNub({
                publish_key   : '109bef91-c638-4d6b-a7f6-18f367631b42',
                subscribe_key : '0ce6d447-bf92-11df-8142-332cdc753f0e'
            });

            // Set Cleanup Buffer Loop
            cleanup_dup_buffer();
        }
 
        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        // Track Analaytics Save
        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        private function tracking_save(message_id:String):void {
            // Save Analytics
            analytics_sync.publish({
                channel : analytics_channel,
                message : analytics[message_id]
            });

            // trace( 'transmitting: ', JSON.stringify(analytics[message_id]));

            // Cleanup in a bit
            setTimeout( function():void {
                delete analytics[message_id];
            }, 10 * 1000 );
        }

        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        // Track Analaytics
        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        private function track(data:Object):void {
            var message:Object    = data['message']
            ,   message_id:String = message[duplicate_key];

            // TODO - TimeToken TR.
            // TODO - Data Center Origin.

            // Unable to track if no MessageID
            if (!message_id) return;

            // Init MessageID Tracking
            if (!(message_id in analytics)) {
                analytics[message_id]                     = {};
                analytics[message_id].ages                = [];
                analytics[message_id].origins             = [];

                analytics[message_id].local_time = now();
                analytics[message_id].message_id = message_id;
                analytics[message_id].message_count = 0;
                analytics[message_id].time_drift = analytics_sync.time_drift;
                analytics[message_id].session = analytics_session;
                analytics[message_id].timetoken_tx = data['timetoken'];
                analytics[message_id].channel = data['channel'];

                // Set Timer for Tracking to Transmit
                setTimeout( tracking_save, 10 * 1000, message_id );
            }

            // Begin Tracking Metrics for Message
            analytics[message_id].message_count++;
            analytics[message_id].ages.push(data['age']);
            analytics[message_id].origins.push(data['origin']||"closest");
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
            age:Number,
            origin:String
        ):void {
            // Assume Message Object and Bail Otherwise
            if (typeof message !== "object") {
                callbacks['error'](
                    'Message Payload: Not an Object: ' + message
                );
                return;
            }

            // Assume Message ID in Object and Bail Otherwise
            if (!(duplicate_key in message)) {
                callbacks['error']('Message Payload: Missing Message ID');
                return;
            }

            // Tracking Analtyics and Deliverability Metrics
            track({
                message   : message,
                channel   : channel,
                timetoken : timetoken,
                age       : age,
                origin    : origin
            });

            // Deduplication
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
                // trace( 'cleaining: ', deduplicates_la[0].message_id );
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
