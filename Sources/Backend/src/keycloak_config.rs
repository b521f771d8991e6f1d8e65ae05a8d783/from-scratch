use actix_web_middleware_keycloak_auth::{AlwaysReturnPolicy, DecodingKey, KeycloakAuth};
use log::info;
use reqwest::Client;
use serde::Deserialize;
use std::env;
use std::error::Error;

#[derive(Deserialize, derive_getters::Getters)]
#[allow(dead_code)]
pub struct RealmConfig {
    realm: String,
    #[serde(rename = "public_key")]
    public_key: String,
    #[serde(rename = "token-service")]
    token_service: String,
    #[serde(rename = "account-service")]
    account_service: String,
    #[serde(rename = "tokens-not-before")]
    tokens_not_before: i32,
}

impl RealmConfig {
    /// Initializes a RealmConfig by fetching and decoding JSON from the given URL.
    /// Returns Result with RealmConfig or an error.
    async fn from_url(url: &str) -> Result<Self, Box<dyn Error>> {
        info!("Downloading realm config from: {}", url);
        let client = Client::new();
        let response = client.get(url).send().await?;
        let realm_config: RealmConfig = response.json().await?;
        Ok(realm_config)
    }

    /// Initializes a RealmConfig from Keycloak server and realm.
    async fn from_keycloak_url(
        keycloak_server: &str,
        keycloak_realm: &str,
    ) -> Result<Self, Box<dyn Error>> {
        let realm_config_url = format!("{}/realms/{}", keycloak_server, keycloak_realm);
        Self::from_url(&realm_config_url).await
    }

    async fn from_keycloak_config(keycloak_config: KeycloakConfig) -> Result<Self, Box<dyn Error>> {
        Self::from_keycloak_url(
            keycloak_config.keycloak_server(),
            keycloak_config.keycloak_realm(),
        )
        .await
    }

    /// Returns the public key as a PEM-formatted string.
    fn get_as_pem(&self) -> String {
        let line_length = 64;
        let header = "-----BEGIN PUBLIC KEY-----";
        let footer = "-----END PUBLIC KEY-----";

        // Remove any whitespace or newlines from the base64 string
        let base64_key = self.public_key.replace(&[' ', '\n', '\r'][..], "");

        // Split the base64 string into lines of 64 characters
        let lines: Vec<String> = base64_key
            .as_bytes()
            .chunks(line_length)
            .map(|chunk| String::from_utf8_lossy(chunk).to_string())
            .collect();

        // Join the header, lines, and footer
        [header.to_string()]
            .into_iter()
            .chain(lines)
            .chain(std::iter::once(footer.to_string()))
            .collect::<Vec<String>>()
            .join("\n")
    }
}

#[derive(derive_getters::Getters)]
struct KeycloakConfig {
    keycloak_server: String,
    keycloak_realm: String,
}

impl KeycloakConfig {
    fn from_env() -> Self {
        let keycloak_server = env::var("KEYCLOAK_URL").expect("KEYCLOAK_URL not set");
        let keycloak_realm = env::var("KEYCLOAK_REALM").expect("KEYCLOAK_REALM not set");
        Self {
            keycloak_server,
            keycloak_realm,
        }
    }
}

pub async fn create_keycloak_config() -> KeycloakAuth<AlwaysReturnPolicy> {
    let public_key = env::var("KEYCLOAK_PUBLIC_KEY");

    return match public_key {
        Ok(public_key) => KeycloakAuth::default_with_pk(
            DecodingKey::from_rsa_pem(public_key.as_str().as_bytes()).unwrap(),
        ),
        Err(_) => {
            info!("No keycloak format given, downloading ...");
            let keycloak_config = KeycloakConfig::from_env();
            let realm_config = RealmConfig::from_keycloak_config(keycloak_config)
                .await
                .expect("Could not download realm config");
            let downloaded_key = realm_config.get_as_pem();
            info!("Downloaded PEM {}", downloaded_key);
            KeycloakAuth::default_with_pk(
                DecodingKey::from_rsa_pem(downloaded_key.as_str().as_bytes())
                    .expect("error decoding keycloak public key"),
            )
        }
    };
}

pub fn setup_server_config() -> (String, u16) {
    let host = env::var("BACKEND_LISTEN_HOSTNAME").unwrap().clone();
    let port = env::var("BACKEND_LISTEN_PORT")
        .unwrap()
        .parse()
        .unwrap_or(8080);
    (host, port)
}
