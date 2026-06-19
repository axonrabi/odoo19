use std::process::Command;

// Learn more about Tauri commands at https://tauri.app/develop/calling-rust/
#[tauri::command]
fn greet(name: &str) -> String {
    format!("Hello, {}! You've been greeted from Rust!", name)
}

#[tauri::command]
fn install_odoo() -> String {
    let output = Command::new("sh")
        .arg("../../lxd_odoo_installer.sh")
        .arg("install")
        .output()
        .expect("Failed to execute install command");

    String::from_utf8_lossy(&output.stdout).to_string()
}

#[tauri::command]
fn start_odoo() -> String {
    let output = Command::new("sh")
        .arg("../../lxd_odoo_installer.sh")
        .arg("start")
        .output()
        .expect("Failed to execute start command");

    String::from_utf8_lossy(&output.stdout).to_string()
}

#[tauri::command]
fn snapshot_odoo() -> String {
    let output = Command::new("sh")
        .arg("../../lxd_odoo_installer.sh")
        .arg("snapshot")
        .output()
        .expect("Failed to execute snapshot command");

    String::from_utf8_lossy(&output.stdout).to_string()
}

#[tauri::command]
fn export_odoo() -> String {
    let output = Command::new("sh")
        .arg("../../lxd_odoo_installer.sh")
        .arg("export")
        .output()
        .expect("Failed to execute export command");

    String::from_utf8_lossy(&output.stdout).to_string()
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_opener::init())
        .invoke_handler(tauri::generate_handler![greet, install_odoo, start_odoo, snapshot_odoo, export_odoo])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
