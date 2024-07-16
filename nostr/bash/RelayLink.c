#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <libwebsockets.h>
#include <jansson.h>
#include <signal.h>

static struct lws_context *context;
static volatile int force_exit = 0;

static const char *relay_url;
static const char *event_json;
static const char *public_key;

void sigint_handler(int sig) {
    force_exit = 1;
    lws_cancel_service(context);
}

static int callback_websockets(struct lws *wsi, enum lws_callback_reasons reason,
                               void *user, void *in, size_t len) {
    switch (reason) {
        case LWS_CALLBACK_CLIENT_ESTABLISHED:
            printf("Client connected to relay\n");
            if (event_json) {
                lws_write(wsi, (unsigned char *) event_json, strlen(event_json), LWS_WRITE_TEXT);
            } else {
                char buffer[256];
                snprintf(buffer, sizeof(buffer), "[\"REQ\", \"sub1\", {\"authors\": [\"%s\"]}]", public_key);
                lws_write(wsi, (unsigned char *) buffer, strlen(buffer), LWS_WRITE_TEXT);
            }
            break;
        case LWS_CALLBACK_CLIENT_RECEIVE:
            printf("Received: %s\n", (char *) in);
            break;
        case LWS_CALLBACK_CLIENT_CONNECTION_ERROR:
            printf("Client connection error\n");
            force_exit = 1;
            break;
        case LWS_CALLBACK_CLIENT_CLOSED:
            printf("Client disconnected from relay\n");
            force_exit = 1;
            break;
        default:
            break;
    }
    return 0;
}

static struct lws_protocols protocols[] = {
    {"example-protocol", callback_websockets, 0, 4096},
    {NULL, NULL, 0, 0} /* terminator */
};

int main(int argc, char **argv) {
    if (argc != 4) {
        fprintf(stderr, "Usage: %s <relay_url> <event_json | NULL> <public_key>\n", argv[0]);
        return 1;
    }

    relay_url = argv[1];
    event_json = (strcmp(argv[2], "NULL") == 0) ? NULL : argv[2];
    public_key = argv[3];

    struct lws_context_creation_info info;
    memset(&info, 0, sizeof(info));
    info.port = CONTEXT_PORT_NO_LISTEN;
    info.protocols = protocols;

    context = lws_create_context(&info);
    if (!context) {
        fprintf(stderr, "lws init failed\n");
        return -1;
    }

    signal(SIGINT, sigint_handler);

    struct lws_client_connect_info ccinfo = {0};
    ccinfo.context = context;
    ccinfo.address = relay_url;
    ccinfo.port = 80;
    ccinfo.path = "/";
    ccinfo.host = lws_canonical_hostname(context);
    ccinfo.origin = "origin";
    ccinfo.protocol = protocols[0].name;
    ccinfo.ssl_connection = 0;

    if (!lws_client_connect_via_info(&ccinfo)) {
        fprintf(stderr, "Client connection failed\n");
        lws_context_destroy(context);
        return -1;
    }

    while (!force_exit) {
        lws_service(context, 1000);
    }

    lws_context_destroy(context);
    return 0;
}
