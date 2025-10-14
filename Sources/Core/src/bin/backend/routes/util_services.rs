use crate::build_information::BuildInformation;
use actix_web::{HttpResponse, Responder, get};

#[get("/version")]
pub async fn version() -> impl Responder {
    format!("{}", env!("CARGO_PKG_VERSION"),)
}

#[get("/build-information")]
pub async fn build_information() -> impl Responder {
    serde_json::to_string(&BuildInformation::from_env())
}

#[get("/status")]
pub async fn status() -> impl Responder {
    format!("👌")
}

#[get("/🫖")]
async fn convert_to_teapot() -> impl Responder {
    println!("Converting this computer into a teapot, please wait ...");
    // TODO add VERY sophisticated code that converts this computer into a teapot
    HttpResponse::ImATeapot()
}

#[cfg(test)]
mod tests {
    use super::*;
    use actix_web::{App, test};

    #[actix_web::test]
    async fn test_version() {
        let app = test::init_service(App::new().service(version)).await;
        let req = test::TestRequest::get().uri("/version").to_request();
        let resp = test::call_and_read_body(&app, req).await;
        assert_eq!(resp, env!("CARGO_PKG_VERSION"));
    }

    #[actix_web::test]
    async fn test_status() {
        let app = test::init_service(App::new().service(status)).await;
        let req = test::TestRequest::get().uri("/status").to_request();
        let resp = test::call_and_read_body(&app, req).await;
        assert_eq!(resp, "👌");
    }
}
