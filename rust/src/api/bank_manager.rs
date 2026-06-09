use std::fs;
use std::path::Path;
use crate::api::audio_types::{SoundBank, BankMeta, PadAssignment};

#[flutter_rust_bridge::frb(sync)]
pub fn save_bank(bank: SoundBank, dir_path: String) -> Result<(), String> {
    let path = Path::new(&dir_path).join(format!("{}.json", bank.meta.name));
    
    // Ensure dir exists
    if let Some(parent) = path.parent() {
        fs::create_dir_all(parent).map_err(|e| format!("Failed to create directories: {e}"))?;
    }

    let serialized = serde_json::to_string_pretty(&bank)
        .map_err(|e| format!("Failed to serialize bank: {e}"))?;

    fs::write(path, serialized)
        .map_err(|e| format!("Failed to write bank file: {e}"))?;

    Ok(())
}

#[flutter_rust_bridge::frb(sync)]
pub fn load_bank(path: String) -> Result<SoundBank, String> {
    let content = fs::read_to_string(&path)
        .map_err(|e| format!("Failed to read bank file: {e}"))?;

    let bank: SoundBank = serde_json::from_str(&content)
        .map_err(|e| format!("Failed to parse bank: {e}"))?;

    Ok(bank)
}

#[flutter_rust_bridge::frb(sync)]
pub fn list_banks(dir_path: String) -> Result<Vec<BankMeta>, String> {
    let path = Path::new(&dir_path);
    if !path.exists() {
        fs::create_dir_all(path).map_err(|e| format!("Failed to create directory: {e}"))?;
        return Ok(Vec::new());
    }

    let entries = fs::read_dir(path)
        .map_err(|e| format!("Failed to read directory: {e}"))?;

    let mut banks = Vec::new();
    for entry in entries {
        if let Ok(entry) = entry {
            let p = entry.path();
            if p.is_file()
                && p.extension()
                    .and_then(|ext| ext.to_str())
                    .is_some_and(|ext| ext.eq_ignore_ascii_case("json"))
            {
                if let Some(path_str) = p.to_str() {
                    if let Ok(bank) = load_bank(path_str.to_string()) {
                        banks.push(bank.meta);
                    }
                }
            }
        }
    }
    Ok(banks)
}

#[flutter_rust_bridge::frb(sync)]
pub fn create_default_bank(name: String, dir_path: String) -> Result<SoundBank, String> {
    let now_str = "2026-06-09T00:00:00Z".to_string(); // Static ISO 8601 for simplicity or fallback
    
    let path = Path::new(&dir_path).join(format!("{}.json", name));
    let path_str = path.to_str().unwrap_or("").to_string();

    let meta = BankMeta {
        name,
        path: path_str,
        pad_count: 16,
        created_at: now_str.clone(),
        modified_at: now_str,
    };

    let mut assignments = Vec::new();
    for pad_index in 0..16 {
        assignments.push(PadAssignment {
            pad_index,
            sound_path: None,
            volume: 1.0,
            loop_enabled: false,
        });
    }

    let bank = SoundBank {
        meta,
        assignments,
    };

    save_bank(bank.clone(), dir_path)?;

    Ok(bank)
}

#[flutter_rust_bridge::frb(sync)]
pub fn delete_bank(path: String) -> Result<(), String> {
    fs::remove_file(path).map_err(|e| format!("Failed to delete bank file: {e}"))
}
