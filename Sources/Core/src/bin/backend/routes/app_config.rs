use actix_web::{HttpResponse, Responder};

use crate::app_config::AppConfig;

#[actix_web::get("/app-config.json")]
async fn app_config() -> impl Responder {
    match AppConfig::from_env() {
        Some(config) => HttpResponse::Ok()
            .content_type("application/json")
            .json(config),
        None => HttpResponse::InternalServerError()
            .body("Could not construct AppConfig from environment"),
    }
}
