#[derive(serde::Serialize, Debug, Eq, PartialEq)]
pub struct BuildInformation {
    cargo_build_profile: String,
    cargo_package_version: String,
    git_commit: String,
    git_branch: String,
    git_commit_date: u128,
    git_status: String,
}

impl BuildInformation {
    pub fn from_env() -> Self {
        BuildInformation {
            cargo_build_profile: env!("CARGO_BUILD_PROFILE").to_string(),
            cargo_package_version: env!("CARGO_PKG_VERSION").to_string(),
            git_commit: env!("GIT_HASH").to_string(),
            git_branch: env!("GIT_BRANCH").to_string(),
            git_status: env!("GIT_STATUS").to_string(),
            git_commit_date: env!("GIT_DATE")
                .parse()
                .expect("error on decoding the date of the last git commit"),
        }
    }

    pub fn get_version(&self) -> String {
        format!("{}@{}", self.git_branch, self.git_commit_date)
    }
}
