#pragma once
// WiFi + MQTT bridge.
// Include from exactly one translation unit (main.cpp).
// Requires wifi_config.h in the project root (copy from wifi_config.h.example).

#if __has_include("../wifi_config.h")
#  include "../wifi_config.h"
#  define MQTT_ENABLED 1
#else
#  define MQTT_ENABLED 0
#endif

#if MQTT_ENABLED

#include <WiFi.h>
#include <PubSubClient.h>

static WiFiClient   _wifiClient;
static PubSubClient _mqttClient(_wifiClient);

static bool _mqttWifiEnabled = false;   // controlled by settings().wifi

// Call once when WiFi setting is toggled on, or on boot if setting is on.
inline void mqttStart() {
  _mqttWifiEnabled = true;
  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  _mqttClient.setServer(MQTT_HOST, MQTT_PORT);
  _mqttClient.setKeepAlive(30);
}

// Call when WiFi setting is toggled off.
inline void mqttStop() {
  _mqttWifiEnabled = false;
  if (_mqttClient.connected()) _mqttClient.disconnect();
  WiFi.disconnect(true);
  WiFi.mode(WIFI_OFF);
}

// Returns true if we're connected and able to publish.
inline bool mqttReady() {
  return _mqttWifiEnabled && _mqttClient.connected();
}

// Reconnect WiFi+MQTT if needed. Call from main loop (non-blocking).
static uint32_t _mqttLastAttempt = 0;
static const uint32_t MQTT_RETRY_MS = 10000;

inline void mqttLoop() {
  if (!_mqttWifiEnabled) return;

  if (_mqttClient.connected()) {
    _mqttClient.loop();
    return;
  }

  uint32_t now = millis();
  if ((int32_t)(now - _mqttLastAttempt) < (int32_t)MQTT_RETRY_MS) return;
  _mqttLastAttempt = now;

  if (WiFi.status() != WL_CONNECTED) {
    WiFi.reconnect();
    return;
  }

  const char* user = strlen(MQTT_USER) ? MQTT_USER : nullptr;
  const char* pass = strlen(MQTT_PASSWORD) ? MQTT_PASSWORD : nullptr;

  // Client ID includes MAC suffix to avoid collisions on shared brokers.
  uint8_t mac[6];
  esp_read_mac(mac, ESP_MAC_WIFI_STA);
  char clientId[24];
  snprintf(clientId, sizeof(clientId), "buddy-%02x%02x%02x", mac[3], mac[4], mac[5]);

  _mqttClient.connect(clientId, user, pass);
}

// Publish a JSON payload to <prefix>/events/<eventType>.
inline void mqttPublish(const char* eventType, const char* jsonPayload) {
  if (!mqttReady()) return;
  char topic[64];
  snprintf(topic, sizeof(topic), MQTT_TOPIC_PREFIX "/events/%s", eventType);
  _mqttClient.publish(topic, jsonPayload);
}

// --- Typed event helpers -------------------------------------------------------

inline void mqttPublishPermission(const char* tool, const char* hint) {
  char buf[256];
  snprintf(buf, sizeof(buf),
    "{\"event\":\"permission\",\"tool\":\"%s\",\"hint\":\"%s\"}",
    tool ? tool : "", hint ? hint : "");
  mqttPublish("permission", buf);
}

inline void mqttPublishDecision(const char* promptId, const char* decision, uint32_t secondsToRespond) {
  char buf[192];
  snprintf(buf, sizeof(buf),
    "{\"event\":\"decision\",\"id\":\"%s\",\"decision\":\"%s\",\"seconds\":%lu}",
    promptId ? promptId : "", decision, (unsigned long)secondsToRespond);
  mqttPublish("decision", buf);
}

inline void mqttPublishState(const char* stateName) {
  char buf[96];
  snprintf(buf, sizeof(buf), "{\"event\":\"state\",\"state\":\"%s\"}", stateName);
  mqttPublish("state", buf);
}

inline void mqttPublishLevelUp(uint8_t level, uint32_t tokens) {
  char buf[96];
  snprintf(buf, sizeof(buf),
    "{\"event\":\"levelup\",\"level\":%u,\"tokens\":%lu}",
    level, (unsigned long)tokens);
  mqttPublish("levelup", buf);
}

inline void mqttPublishHeartbeat(const char* stateName, uint8_t level, uint32_t tokens,
                                  uint16_t approvals, uint16_t denials) {
  char buf[192];
  snprintf(buf, sizeof(buf),
    "{\"event\":\"heartbeat\",\"state\":\"%s\",\"level\":%u,\"tokens\":%lu"
    ",\"approvals\":%u,\"denials\":%u,\"ip\":\"%s\"}",
    stateName, level, (unsigned long)tokens, approvals, denials,
    WiFi.localIP().toString().c_str());
  mqttPublish("heartbeat", buf);
}

#else  // !MQTT_ENABLED — stub everything out so main.cpp compiles unchanged

inline void mqttStart()   {}
inline void mqttStop()    {}
inline bool mqttReady()   { return false; }
inline void mqttLoop()    {}
inline void mqttPublish(const char*, const char*) {}
inline void mqttPublishPermission(const char*, const char*) {}
inline void mqttPublishDecision(const char*, const char*, uint32_t) {}
inline void mqttPublishState(const char*) {}
inline void mqttPublishLevelUp(uint8_t, uint32_t) {}
inline void mqttPublishHeartbeat(const char*, uint8_t, uint32_t, uint16_t, uint16_t) {}

#endif  // MQTT_ENABLED
