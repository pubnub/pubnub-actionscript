package com.pubnub {
    import flash.events.Event;
    import flash.events.IOErrorEvent;
    import flash.events.TimerEvent;
    import flash.utils.Timer;
    import flash.utils.setTimeout;
    import flash.net.URLStream;
    import flash.net.URLRequest;
    import flash.utils.ByteArray;

    import com.adobe.crypto.MD5;
    import com.adobe.crypto.SHA256;
    import com.hurlant.crypto.symmetric.AESKey;
    import com.hurlant.crypto.symmetric.CBCMode;
    import com.hurlant.crypto.symmetric.PKCS5;
    import com.hurlant.util.Base64;
    import com.hurlant.util.Hex;

    public class PubNub {
        private var subscribe_timeout:Number;
        private var time_drift:Number;
        private var loader:URLStream;
        private var timetoken:String;
        private var resume_time:String;
        private var channels:Object;
        private var ssl:Boolean;
        private var origin:String;
        private var cipher_key:String;
        private var publish_key:String;
        private var subscribe_key:String;
        private var callbacks:Object;
        private var connected:Boolean;
        private var disconnected:Boolean;
        private static const ALPHA_CHAR_CODES:Array = [
            48, 49, 50, 51, 52, 53, 54, 55,
            56, 57, 65, 66, 67, 68, 69, 70
        ];

        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        // Initalize
        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        public function PubNub(settings:Object) {
            loader            = new URLStream();
            publish_key       = settings['publish_key']   || "demo";
            subscribe_key     = settings['subscribe_key'] || "demo";
            cipher_key        = settings['cipher_key']    || false;
            origin            = settings['origin']        || false;
            ssl               = settings['ssl']           || false;
            connected         = false;
            disconnected      = false;
            channels          = {'_':'_'};
            callbacks         = {};
            timetoken         = "0";
            resume_time       = "0";
            subscribe_timeout = 310000;
            time_drift        = 0;

            callbacks['message']    = settings['message'];
            callbacks['idle']       = settings['idle'];
            callbacks['connect']    = settings['connect'];
            callbacks['reconnect']  = settings['reconnect'];
            callbacks['disconnect'] = settings['disconnect'];

            // Detect Local Clock Drift
            detect_time_detla();
            var timer:Timer = new Timer(5000);
            timer.addEventListener(
                TimerEvent.TIMER,
                function(event:TimerEvent):void { detect_time_detla(); }
            );
            timer.start();

            // Event Handles for Inboud Messages
            loader.addEventListener( Event.COMPLETE,        received );
            loader.addEventListener( IOErrorEvent.IO_ERROR, error    );
            loader.addEventListener( Event.CLOSE,           error    );
        }

        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        // Subscribe
        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        public function subscribe(uargs:Object):void {
            var args:Object = uargs       || {};
            timetoken = args['timetoken'] || "0";
            add_channels(args['channels'] || []);

            // Begin Stream
            subscribe_request([
                ssl ? 'https:/' : 'http:/',
                get_origin(),
                'subscribe',
                subscribe_key,
                get_channels(),
                '0',
                timetoken
            ].join('/'));
        }

        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        // Publish
        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        public function publish(uargs:Object):void {
            var callback = uargs['response'] || function():void{}
            ,   channel  = uargs['channel']  || "_"
            ,   message  = JSON.stringify(uargs['message'] || "_")
            ,   url      = [
                    ssl ? 'https:/' : 'http:/',
                    get_origin(),
                    'publish',
                    publish_key,
                    subscribe_key,
                    '0',
                    channel,
                    '0',
                    cipher_key ? encrypt( cipher_key, message ) : message
            ].join('/');

            // Publish Data
            basic_request( url, callback );
        }

        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        // Get Origin
        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        private function get_origin():String {
            if (origin) return origin;
            return getUID().split('-')[0] + '.pubnub.com';
        }

        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        // Add to Channel Collection
        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        private function add_channels(chans:Array):void {
            for (var chan:Number = 0; chans.length > chan; chan++) {
                channels[chans[chan]] = chans[chan];
            }
        }

        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        // Create list of Channels and Subscribe to Data Feed
        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        private function get_channels():String {
            var chans:Array = [];
            for (var chan:String in channels) chans.push(chan);
            return chans.sort().join(',');
        }

        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        // Upstream Data Connection
        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        private function subscribe_request(url:String):void {
            var request:URLRequest = new URLRequest(url);
            request.idleTimeout = subscribe_timeout;
            try { loader.load(request); }
            catch(e:Error) { error(e as Object); }
        }

        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        // Data Received as Downstream
        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        private function received(event:Event):void {
            var loader:URLStream = URLStream(event.target);

            try {
                var data:String = loader.data;
                process(JSON.parse(data) as Array);
            }
            catch(e:Error) {
                error(e as Object);
            }
            // TODO (add a basic time reqeust for detecting tempaorary errors)
            // TODO (add a basic time reqeust for detecting tempaorary errors)
            // TODO (add a basic time reqeust for detecting tempaorary errors)
            // TODO (add a basic time reqeust for detecting tempaorary errors)
        }

        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        // Process Payload
        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        private function process(data:Array):void {
            var messages:Array = data[0];
            var tt:String      = data[1];
            var chans:Array    = (data[2] || "").split(/,/);
            var latency:Number = detect_latency(Number(tt));

            // Connect Callback
            if (!connected) {
                connected = true;
                'connect' in callbacks && callbacks['connect']();
            }

            // Reconnect Callback
            if (disconnected) {
                disconnected = false;
                'reconnect' in callbacks && callbacks['reconnect']();
            }

            // Process User Callback Per Message
            for (var msg:Number = 0; messages.length > msg; msg++) {
                var message:Object = messages[msg];

                if (cipher_key) {
                    try {
                        message = decrypt(
                            cipher_key,
                            message as String
                        ) as Object;
                        message = JSON.parse(message as String) as Object;
                    }
                    catch(e:Error) {
                        message = "Failed Decryption";
                    }
                }

                callbacks['message'](
                    message as Object,
                    chans[msg],
                    tt,
                    latency
                );
            }

            // Idle Callback
            if ('idle' in callbacks) callbacks['idle'](tt);

            // Use Resumable TT?
            var ttoken:String = tt;
            if (timetoken == "0" && resume_time != "0") ttoken = resume_time;

            // Continue Processing Received Message Bundles
            setTimeout( subscribe, 10, { timetoken : ttoken } );

            // Set Last Known Timetoken
            resume_time = tt;
        }

        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        // Something is Not Right
        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        private function error(event:Object):void {
            var resume:Boolean = true;

            // Disconnect Callback
            if (!disconnected) {
                disconnected = true;
                if ('disconnect' in callbacks)
                    resume = callbacks['disconnect'](event) && resume;
            }

            // Resume
            if (resume) setTimeout( subscribe, 1000, {} );
        }


        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        // Detect Age of Message
        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        private function detect_latency(tt:Number):Number {
            var adjusted_time:Number = (new Date()).time - time_drift;
            return adjusted_time - tt / 10000;
        }

        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        // Detect Local Clock Drift
        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        public function detect_time_detla():void {
            var stime:Number = (new Date()).time;
            basic_request( 'https://ps.pubnub.com/time/0', calculate );
            function calculate(data:Object):void {
                if (!data) return;

                var time:Number    = data[0]
                ,   ptime:Number   = time / 10000
                ,   latency:Number = ((new Date()).time - stime) / 2;

                time_drift = (new Date()).time - (ptime + latency);
            }
        }

        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        // Basic URL Request
        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        public function basic_request( url:String, callback:Function ):void {
            var loader:URLLoader   = new URLLoader()
            var request:URLRequest = new URLRequest(url);
            request.idleTimeout    = 10000;

            // Event Handles
            loader.addEventListener( Event.COMPLETE,        basic_received );
            loader.addEventListener( IOErrorEvent.IO_ERROR, basic_error    );
            loader.addEventListener( Event.CLOSE,           basic_error    );

            // Try Request
            try { loader.load(request); }
            catch(e:Error) { error(e as Object); }

            function basic_received(event:Event):void {
                var loader:URLLoader = URLLoader(event.target);
                try {
                    var data:String = loader.data;
                    callback(JSON.parse(data) as Array);
                }
                catch(e:Error) {
                    basic_error(e as Event);
                }
            }

            function basic_error(event:Event):void {
                callback(false);
            }
        }

        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        // UUID
        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        public static function getUID():String {
            var temp:Array = new Array(36);
            var index:int = 0;
            var i:int;
            var j:int;

            for (i = 0; i < 8; i++) {
                temp[index++] =
                    ALPHA_CHAR_CODES[Math.floor(Math.random() * 16)];
            }

            for (i = 0; i < 3; i++) {
                temp[index++] = 45; // charCode for "-"
                for (j = 0; j < 4; j++){
                    temp[index++] =
                        ALPHA_CHAR_CODES[Math.floor(Math.random() * 16)];
                }
            }

            temp[index++] = 45; // charCode for "-"

            for (i = 0; i < 8; i++) {
                temp[index++] =
                    ALPHA_CHAR_CODES[Math.floor(Math.random() * 16)];
            }

            for (j = 0; j < 4; j++) {
                temp[index++] =
                    ALPHA_CHAR_CODES[Math.floor(Math.random() * 16)];
            }

            var time:Number = new Date().time;
            return String.fromCharCode.apply( null, temp );
        }

        public static function encode(args:String):String{
            return encodeURIComponent(args);

        }

        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        // Encrypt
        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        static public function encrypt(
            cipher_key:String,
            plainStr:String
        ):String {
            var key:ByteArray = hashKey(cipher_key);
            var data:ByteArray = Hex.toArray(Hex.fromString(plainStr));
            var cbc:CBCMode = new CBCMode(new AESKey(key), new PKCS5());
            cbc.IV = Hex.toArray(Hex.fromString("0123456789012345"));
            cbc.encrypt(data);
            var encryptedEncodedData:String = Base64.encodeByteArray(data);
            return encryptedEncodedData;
        }

        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        // Decrypt
        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        static public function decrypt(
            cipher_key:String,
            cipherText:String
        ):String {
            var decodedCipherText:ByteArray = Base64.decodeToByteArray(cipherText)
            var key:ByteArray = hashKey(cipher_key);
            var cbc:CBCMode = new CBCMode(new AESKey(key), new PKCS5());
            cbc.IV = Hex.toArray(Hex.fromString("0123456789012345"));
            cbc.decrypt(decodedCipherText);
            return Hex.toString(Hex.fromArray(decodedCipherText));
        }

        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        // Hash Key
        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        static public function hashKey(cipher_key:String):ByteArray {
            //var sha256:SHA256 = new SHA256;
            var hexFromString:String = Hex.fromString(cipher_key);
            var src:ByteArray = Hex.toArray(hexFromString);
            var hexCipherKey:String = SHA256.hashBytes(src);
            var cipherString:String = hexCipherKey.slice(0, 32);
            var key:ByteArray = Hex.toArray(Hex.fromString(cipherString));
            return key;
        }

        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        // MD5
        // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        static public function md5Key(s:String):String {
            var ba:ByteArray = new ByteArray();
            ba.writeUTFBytes(s);
            return MD5.hashBinary(ba);
        }
    }
}
