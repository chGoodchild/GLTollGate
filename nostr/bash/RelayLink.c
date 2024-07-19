#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <libwebsockets.h>
#include <signal.h>
#include <regex.h>
#include <openssl/ssl.h>
#include <arpa/inet.h>

static struct lws_context *context;
static volatile int force_exit = 0;
static volatile int eose_received = 0; // Flag for EOSE
static volatile int event_published = 0; // Flag for event published

static const char *relay_url;
static const char *event_json_path;
static const char *public_key;

void sigint_handler(int sig) {
    force_exit = 1;
    lws_cancel_service(context);
}

static int callback_websockets(struct lws *wsi, enum lws_callback_reasons reason,
                               void *user, void *in, size_t len) {
    switch (reason) {
        case LWS_CALLBACK_CLIENT_ESTABLISHED:
            // Reading JSON data from file
            FILE *file = fopen(event_json_path, "r");
            if (!file) {
                fprintf(stderr, "Failed to open JSON file\n");
                return -1;
            }
            fseek(file, 0, SEEK_END);
            long fsize = ftell(file);
            fseek(file, 0, SEEK_SET);  // same as rewind(file);
            char *string = malloc(fsize + 1);
            fread(string, 1, fsize, file);
            fclose(file);
            string[fsize] = 0;
            
            // Sending JSON data
            lws_write(wsi, (unsigned char *)string, strlen(string), LWS_WRITE_TEXT);
            free(string);
            break;
        // In callback_websockets function
        case LWS_CALLBACK_CLIENT_WRITEABLE:
            if (event_json_path) {  // Change to event_json_path
                FILE *file = fopen(event_json_path, "r");
                if (!file) {
                    fprintf(stderr, "Failed to open JSON file\n");
                    return -1;
                }
                fseek(file, 0, SEEK_END);
                long fsize = ftell(file);
                fseek(file, 0, SEEK_SET);
                char *string = malloc(fsize + 1);
                fread(string, 1, fsize, file);
                fclose(file);
                string[fsize] = 0;
        
                lws_write(wsi, (unsigned char *)string, strlen(string), LWS_WRITE_TEXT);
                free(string);
            }
            break;
        case LWS_CALLBACK_CLIENT_RECEIVE:
            printf("%s\n", (char *)in);
            if (strstr((char *)in, "\"EOSE\"")) {
                eose_received = 1; // Set the flag when EOSE is received
                lws_cancel_service(context); // Exit the service loop
            } else if (strstr((char *)in, "\"OK\"")) {
                event_published = 1; // Set the flag when the event is acknowledged
                lws_cancel_service(context); // Exit the service loop
            }
            break;
        case LWS_CALLBACK_CLIENT_CONNECTION_ERROR:
            fprintf(stderr, "Client connection error: %s\n", in ? (char *)in : "Unknown error");
            force_exit = 1;
            break;
        case LWS_CALLBACK_CLIENT_CLOSED:
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

void parse_url(const char *url, char *hostname, char *path, int *port, int *use_ssl) {
    regex_t regex;
    regmatch_t pmatch[6];
    const char *pattern = "^(wss?)://([^:/]+)(:([0-9]+))?(/.*)?$";
    regcomp(&regex, pattern, REG_EXTENDED);
    if (regexec(&regex, url, 6, pmatch, 0) == 0) {
        if (strncmp(url + pmatch[1].rm_so, "wss", 3) == 0) {
            *use_ssl = 1;
        } else {
            *use_ssl = 0;
        }
        snprintf(hostname, pmatch[2].rm_eo - pmatch[2].rm_so + 1, "%.*s", (int)(pmatch[2].rm_eo - pmatch[2].rm_so), url + pmatch[2].rm_so);
        if (pmatch[4].rm_so != -1) {
            *port = atoi(url + pmatch[4].rm_so);
        } else {
            *port = *use_ssl ? 443 : 80;
        }
        if (pmatch[5].rm_so != -1) {
            snprintf(path, pmatch[5].rm_eo - pmatch[5].rm_so + 1, "%.*s", (int)(pmatch[5].rm_eo - pmatch[5].rm_so), url + pmatch[5].rm_so);
        } else {
            strcpy(path, "/");
        }
    }
    regfree(&regex);
}

int main(int argc, char **argv) {
    if (argc != 4) {
        fprintf(stderr, "Usage: %s <relay_url> <event_json_path> <public_key>\n", argv[0]);
        return 1;
    }

    relay_url = argv[1];
    event_json_path = argv[2];  // Changed variable name for clarity
    public_key = argv[3];

    if (!relay_url || !event_json_path || !public_key) {
        fprintf(stderr, "Error: Missing required arguments.\n");
        return 1;
    }

    char hostname[256], path[256];
    int port, use_ssl;
    parse_url(relay_url, hostname, path, &port, &use_ssl);

    struct lws_context_creation_info info = {0};
    info.port = CONTEXT_PORT_NO_LISTEN;
    info.protocols = protocols;
    lws_set_log_level(LLL_ERR | LLL_WARN | LLL_NOTICE | LLL_INFO | LLL_DEBUG, NULL);

    if (use_ssl) {
        info.options |= LWS_SERVER_OPTION_DO_SSL_GLOBAL_INIT;
        info.ssl_ca_filepath = "/etc/ssl/certs/ca-certificates.crt";
        info.ssl_cipher_list = "DEFAULT:!DH";
    }

    context = lws_create_context(&info);
    if (!context) {
        fprintf(stderr, "Failed to create LWS context\n");
        return -1;
    }

    signal(SIGINT, sigint_handler);

// In main function, struct lws_client_connect_info initialization
    struct lws_client_connect_info ccinfo = {
        .context = context,
        .address = hostname,
        .port = port,
        .path = path,
        .host = hostname,
        .origin = hostname,
        .ssl_connection = use_ssl ? LCCSCF_USE_SSL : 0, // Correct flag for SSL
        .protocol = protocols[0].name
    };
    if (!lws_client_connect_via_info(&ccinfo)) {
        fprintf(stderr, "Connection attempt failed\n");
        lws_context_destroy(context);
        return -1;
    }

    while (!force_exit && !event_published && !eose_received) {
        lws_service(context, 100);
    }

    lws_context_destroy(context);
    return 0;
}

