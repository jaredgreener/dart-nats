const DEFAULT_PORT = '4222';

const DEFAULT_PRE = 'nats://localhost:';
const DEFAULT_URI = DEFAULT_PRE + DEFAULT_PORT;

// Reconnect Parameters, 2 sec wait, 10 tries
const DEFAULT_RECONNECT_TIME_WAIT = 2 * 1000;
const DEFAULT_MAX_RECONNECT_ATTEMPTS = 10;

// Ping interval
const DEFAULT_PING_INTERVAL = 2 * 60 * 1000; // 2 minutes
const DEFAULT_MAX_PING_OUT = 2;

const CR_LF = '\r\n';
const CR_LF_LEN = CR_LF.length;
const EMPTY = '';

// NATS commands
const MSG = "MSG ";
const PUB = "PUB ";
const SUB = "SUB ";
const UNSUB = "UNSUB ";
const INFO = "INFO ";
const PING = "PING";
const PONG = "PONG";
const CONNECT = "CONNECT ";
const OK = "+OK";
const ERR = "-ERR";

const DISCONNECTING_ERRORS = [
  "'Unknown Protocol Operation'",
  "'Attempted To Connect To Route Port'",
  "'Authorization Violation'",
  "'Authorization Timeout'",
  "'Invalid Client Protocol'",
  "'Maximum Control Line Exceeded'",
  "'Parser Error'",
  "'Secure Connection - TLS Required'",
  "'Stale Connection'",
  "'Maximum Connections Exceeded'",
  "'Slow Consumer'",
  "'Maximum Payload Violation'",
];

const STAYOPEN_ERRORS = [
  "'Invalid Subject'",
  "'Permissions Violation for Subscription to",
  "'Permissions Violation for Publish to",
];

enum NATS_STATUS{
  UNINITIALIZED,
  INITIALIZED,
  RECONNECTING,
  CONNECTING,
  CONNECTED,
  DISCONNECTING,
  DISCONNECTED,
  QUERYING
}