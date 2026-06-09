use std::fs;
use std::path::Path;
use hound::{WavReader, WavWriter, WavSpec, SampleFormat};
use crate::api::audio_types::{WavData, SoundMeta};

#[flutter_rust_bridge::frb(sync)]
pub fn save_wav(
    path: String,
    samples: Vec<f32>,
    sample_rate: u32,
    channels: u16,
) -> Result<(), String> {
    let spec = WavSpec {
        channels,
        sample_rate,
        bits_per_sample: 16,
        sample_format: SampleFormat::Int,
    };

    let mut writer = WavWriter::create(&path, spec)
        .map_err(|e| format!("Failed to create WAV writer: {e}"))?;

    for sample in samples {
        // Clamp and scale to i16 range
        let clamped = sample.clamp(-1.0, 1.0);
        let scaled = (clamped * i16::MAX as f32) as i16;
        writer.write_sample(scaled)
            .map_err(|e| format!("Failed to write sample: {e}"))?;
    }

    writer.finalize().map_err(|e| format!("Failed to finalize WAV: {e}"))?;
    Ok(())
}

#[flutter_rust_bridge::frb(sync)]
pub fn load_wav(path: String) -> Result<WavData, String> {
    let mut reader = WavReader::open(&path)
        .map_err(|e| format!("Failed to open WAV file: {e}"))?;
    let spec = reader.spec();

    let mut samples = Vec::new();
    match (spec.sample_format, spec.bits_per_sample) {
        (SampleFormat::Int, 16) => {
            for sample in reader.samples::<i16>() {
                let s = sample.map_err(|e| format!("Failed to read sample: {e}"))?;
                samples.push(s as f32 / i16::MAX as f32);
            }
        }
        (SampleFormat::Int, 24) => {
            // hound reads 24-bit samples as i32
            for sample in reader.samples::<i32>() {
                let s = sample.map_err(|e| format!("Failed to read sample: {e}"))?;
                samples.push(s as f32 / 8388607.0); // 2^23 - 1
            }
        }
        (SampleFormat::Int, 32) => {
            for sample in reader.samples::<i32>() {
                let s = sample.map_err(|e| format!("Failed to read sample: {e}"))?;
                samples.push(s as f32 / i32::MAX as f32);
            }
        }
        (SampleFormat::Float, 32) => {
            for sample in reader.samples::<f32>() {
                let s = sample.map_err(|e| format!("Failed to read sample: {e}"))?;
                samples.push(s);
            }
        }
        _ => return Err(format!("Unsupported WAV format: {:?}", spec)),
    }

    Ok(WavData {
        samples,
        sample_rate: spec.sample_rate,
        channels: spec.channels,
    })
}

#[flutter_rust_bridge::frb(sync)]
pub fn get_sound_meta(path: String) -> Result<SoundMeta, String> {
    let file = fs::File::open(&path)
        .map_err(|e| format!("Failed to open file: {e}"))?;
    let metadata = file.metadata()
        .map_err(|e| format!("Failed to get file metadata: {e}"))?;
    let file_size_bytes = metadata.len();

    let reader = WavReader::new(file)
        .map_err(|e| format!("Failed to parse WAV header: {e}"))?;
    let spec = reader.spec();
    let num_samples = reader.duration();
    let duration_ms = ((num_samples as f64 / spec.sample_rate as f64) * 1000.0) as u32;

    let name = Path::new(&path)
        .file_name()
        .and_then(|n| n.to_str())
        .unwrap_or("Unknown")
        .to_string();

    Ok(SoundMeta {
        name,
        path,
        duration_ms,
        sample_rate: spec.sample_rate,
        channels: spec.channels,
        file_size_bytes,
    })
}

#[flutter_rust_bridge::frb(sync)]
pub fn list_sounds_in_dir(dir_path: String) -> Result<Vec<SoundMeta>, String> {
    let path = Path::new(&dir_path);
    if !path.exists() {
        fs::create_dir_all(path).map_err(|e| format!("Failed to create directory: {e}"))?;
        return Ok(Vec::new());
    }

    let entries = fs::read_dir(path)
        .map_err(|e| format!("Failed to read directory: {e}"))?;

    let mut sounds = Vec::new();
    for entry in entries {
        if let Ok(entry) = entry {
            let p = entry.path();
            if p.is_file()
                && p.extension()
                    .and_then(|ext| ext.to_str())
                    .is_some_and(|ext| ext.eq_ignore_ascii_case("wav"))
            {
                if let Some(path_str) = p.to_str() {
                    if let Ok(meta) = get_sound_meta(path_str.to_string()) {
                        sounds.push(meta);
                    }
                }
            }
        }
    }
    Ok(sounds)
}

#[flutter_rust_bridge::frb(sync)]
pub fn delete_sound(path: String) -> Result<(), String> {
    fs::remove_file(path).map_err(|e| format!("Failed to delete file: {e}"))
}
