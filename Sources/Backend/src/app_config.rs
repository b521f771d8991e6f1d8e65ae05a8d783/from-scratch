use wasm_bindgen::prelude::wasm_bindgen;

#[wasm_bindgen]
#[derive(serde::Serialize, serde::Deserialize, Debug)]
pub struct AppConfig {
    #[serde(flatten)]
    fields: std::collections::HashMap<String, String>,
}

#[wasm_bindgen]
impl AppConfig {
    pub fn from_env() -> Option<Self> {
        let prefixes = env!("APP_CONFIG_EXPORT_TO_FRONTEND_PREFIXES")
            .split(env!("LIST_SEPERATOR"))
            .map(|s| s.trim().to_string())
            .collect::<Vec<_>>();

        let excludes = env!("APP_CONFIG_EXPORT_TO_FRONTEND_EXCLUDE")
            .split(env!("LIST_SEPERATOR"))
            .map(|s| s.trim().to_string())
            .collect::<Vec<_>>();
        let fields = std::env::vars()
            .filter(|(key, _)| prefixes.iter().any(|prefix| key.starts_with(prefix)))
            .filter(|(key, _)| !excludes.contains(key))
            .collect::<std::collections::HashMap<_, _>>();

        Some(Self { fields })
    }

    /// Gets the value associated with the given key from the fields.
    pub fn get(&self, key: &str) -> Option<String> {
        self.fields.get(key).cloned()
    }

    #[wasm_bindgen(js_name = fromJson)]
    pub fn from_json(json: &str) -> Option<Self> {
        serde_json::from_str(json).ok()
    }

    #[wasm_bindgen(js_name = toJson)]
    pub fn to_json(&self) -> String {
        serde_json::to_string(&self).unwrap_or_default()
    }
}
