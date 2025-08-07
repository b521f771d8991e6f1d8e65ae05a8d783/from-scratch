use crate::keycloak_config;
use actix_web_middleware_keycloak_auth::{AlwaysReturnPolicy, KeycloakAuth};

// can we use this here? https://diesel.rs/
// https://actix.rs/docs/application/
#[derive(derive_getters::Getters)]
pub struct AppState {
    server_port: u16,
    server_host: String,
    keycloak_config: KeycloakAuth<AlwaysReturnPolicy>,
}

impl AppState {
    pub async fn from_environment() -> AppState {
        let keycloak_config = keycloak_config::create_keycloak_config();
        let (server_host, server_port) = keycloak_config::setup_server_config();

        AppState {
            server_port,
            server_host,
            keycloak_config: keycloak_config.await,
        }
    }
}
