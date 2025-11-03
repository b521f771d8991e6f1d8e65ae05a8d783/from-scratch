use std::process::Command;

fn get_build_profile_name() -> String {
    // The profile name is always the 3rd last part of the path (with 1 based indexing).
    // e.g. /code/core/target/cli/build/my-build-info-9f91ba6f99d7a061/out
    std::env::var("OUT_DIR")
        .unwrap()
        .split(std::path::MAIN_SEPARATOR)
        .nth_back(3)
        .unwrap_or_else(|| "unknown")
        .to_string()
}

fn parse_git() {
    {
        let output = Command::new("git")
            .args(&["rev-parse", "HEAD"])
            .output()
            .unwrap();
        let git_hash = String::from_utf8(output.stdout).unwrap();
        println!("cargo:rustc-env=GIT_HASH={}", git_hash.trim());
    }

    {
        let output = Command::new("git")
            .args(&["rev-parse", "--abbrev-ref", "HEAD"])
            .output()
            .unwrap();
        let git_branch = String::from_utf8(output.stdout).unwrap();
        println!("cargo:rustc-env=GIT_BRANCH={}", git_branch.trim());
    }

    {
        let output = Command::new("git")
            .args(&["log", "-1", "--pretty=%ct"])
            .output()
            .unwrap();
        let git_date = String::from_utf8(output.stdout).unwrap();
        println!("cargo:rustc-env=GIT_DATE={}", git_date);
    }

    {
        let output = Command::new("git")
            .args(&["status", "--porcelain"])
            .output()
            .unwrap();
        let git_status = String::from_utf8(output.stdout)
            .unwrap()
            .replace('\n', "; ");
        println!("cargo:rustc-env=GIT_STATUS={}", git_status.trim());
    }

    {
        let build_profile_name = get_build_profile_name();
        println!("cargo:rustc-env=CARGO_BUILD_PROFILE={}", build_profile_name);
    }
}

fn main() {
    parse_git();
}
