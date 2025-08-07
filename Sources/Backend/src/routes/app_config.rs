use crate::app_config::AppConfig;
use actix_web::{HttpResponse, Responder};

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
