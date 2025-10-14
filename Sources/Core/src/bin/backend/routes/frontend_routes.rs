use actix_web::http::Error;
use actix_web::{HttpResponse, web};
use log::info;

#[derive(rust_embed::Embed)]
#[folder = "../UI/dist"]
pub struct WebAppData;

impl WebAppData {
    fn lookup(path: &str) -> Result<HttpResponse, Error> {
        match Self::get(path) {
            Some(content) => Ok(HttpResponse::Ok()
                .content_type(mime_guess::from_path(path).first_or_octet_stream().as_ref())
                .body(content.data.to_owned())),
            None => Ok(HttpResponse::NotFound().body("404 Not Found")),
        }
    }

    #[allow(dead_code)]
    pub fn debug_list() {
        info!("Found the following files in WebAppData:");
        for file in WebAppData::iter() {
            info!("- {}", file);
        }
    }
}

#[actix_web::get("/")]
async fn root() -> Result<HttpResponse, Error> {
    WebAppData::lookup("index.html")
}

#[actix_web::get("/index.html")]
async fn index_html() -> Result<HttpResponse, Error> {
    Ok(HttpResponse::PermanentRedirect()
        .append_header(("Location", "/"))
        .finish())
}

pub fn add_services(app: &mut web::ServiceConfig) {
    // Dynamically add all files in WebAppData as services, including all paths
    for file in WebAppData::iter() {
        let path = file.as_ref();
        let route_path = format!("/{}", path);
        let file_path = path.to_string();

        if route_path.eq("/index.html") {
            continue;
        }

        let closure = move || {
            let file_path = file_path.clone(); // Clone for the async block
            async move {
                info!("Serving {}", file_path);
                WebAppData::lookup(&file_path).expect("failed to extract")
            }
        };

        // expo gives us errors if we try to access e.g. /screen.html, because, for expo, the screen is called /screen, so we need add those, too
        if route_path.ends_with(".html") {
            let expo_route_path = route_path.strip_suffix(".html").unwrap();
            app.service(
                actix_web::web::resource(vec![expo_route_path, &route_path])
                    .route(web::get().to(closure)),
            );
            info!("Registered routes [{}, {}]", expo_route_path, route_path);
        } else {
            // not a html file, nothing to do 😀
            info!("Registered routes {}", route_path);
            app.route(&route_path, web::get().to(closure.clone()));
        }
    }

    app.service(root);
    app.service(index_html);
}

#[cfg(test)]
mod tests {
    use super::*;
    use actix_web::{App, test};

    #[actix_web::test]
    async fn test_root() {
        let app = test::init_service(App::new().service(root)).await;
        let req = test::TestRequest::get().uri("/").to_request();
        let resp = test::call_service(&app, req).await;
        assert!(resp.status().is_success());
    }
}
