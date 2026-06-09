use serde::{Serialize, Deserialize};

#[flutter_rust_bridge::frb]
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SoundMeta {
    pub name: String,
    pub path: String,
    pub duration_ms: u32,
    pub sample_rate: u32,
    pub channels: u16,
    pub file_size_bytes: u64,
}

#[flutter_rust_bridge::frb]
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BankMeta {
    pub name: String,
    pub path: String,
    pub pad_count: u8,
    pub created_at: String, // ISO 8601
    pub modified_at: String,
}

#[flutter_rust_bridge::frb]
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PadAssignment {
    pub pad_index: u8,
    pub sound_path: Option<String>,
    pub volume: f32, // 0.0 to 1.0
    pub loop_enabled: bool,
}

#[flutter_rust_bridge::frb]
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SoundBank {
    pub meta: BankMeta,
    pub assignments: Vec<PadAssignment>,
}

#[flutter_rust_bridge::frb]
#[derive(Debug, Clone)]
pub struct WavData {
    pub samples: Vec<f32>,
    pub sample_rate: u32,
    pub channels: u16,
}
