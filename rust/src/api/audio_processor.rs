#[flutter_rust_bridge::frb(sync)]
pub fn normalize_samples(samples: Vec<f32>) -> Vec<f32> {
    if samples.is_empty() {
        return samples;
    }

    let mut max_val: f32 = 0.0;
    for &sample in &samples {
        let abs = sample.abs();
        if abs > max_val {
            max_val = abs;
        }
    }

    if max_val < 1e-5 {
        return samples;
    }

    let scale = 0.98 / max_val; // Normalize to -0.98 peak for headroom
    samples.into_iter().map(|s| s * scale).collect()
}

#[flutter_rust_bridge::frb(sync)]
pub fn adjust_volume(samples: Vec<f32>, gain: f32) -> Vec<f32> {
    samples.into_iter().map(|s| s * gain).collect()
}

#[flutter_rust_bridge::frb(sync)]
pub fn trim_samples(samples: Vec<f32>, start_sample: u32, end_sample: u32) -> Vec<f32> {
    let len = samples.len() as u32;
    let start = start_sample.min(len) as usize;
    let end = end_sample.min(len).max(start_sample) as usize;
    samples[start..end].to_vec()
}

#[flutter_rust_bridge::frb(sync)]
pub fn get_waveform_data(samples: Vec<f32>, num_points: u32) -> Vec<f32> {
    if samples.is_empty() || num_points == 0 {
        return vec![0.0; num_points as usize];
    }

    let chunk_size = (samples.len() as f32 / num_points as f32).max(1.0);
    let mut waveform = Vec::with_capacity(num_points as usize);

    for i in 0..num_points {
        let start = (i as f32 * chunk_size) as usize;
        let end = (((i + 1) as f32 * chunk_size) as usize).min(samples.len());
        if start >= samples.len() {
            waveform.push(0.0);
            continue;
        }

        let slice = &samples[start..end];
        if slice.is_empty() {
            waveform.push(0.0);
            continue;
        }

        // Compute Root Mean Square (RMS) for this chunk
        let sum_sq: f32 = slice.iter().map(|&s| s * s).sum();
        let rms = (sum_sq / slice.len() as f32).sqrt();
        waveform.push(rms);
    }

    waveform
}

#[flutter_rust_bridge::frb(sync)]
pub fn get_peak_level(samples: Vec<f32>) -> f32 {
    let mut peak: f32 = 0.0;
    for &sample in &samples {
        let abs = sample.abs();
        if abs > peak {
            peak = abs;
        }
    }
    peak
}

#[flutter_rust_bridge::frb(sync)]
pub fn mix_samples(tracks: Vec<Vec<f32>>, volumes: Vec<f32>) -> Vec<f32> {
    if tracks.is_empty() {
        return Vec::new();
    }

    let max_len = tracks.iter().map(|t| t.len()).max().unwrap_or(0);
    let mut mixed = vec![0.0; max_len];

    for (track_idx, track) in tracks.iter().enumerate() {
        let vol = volumes.get(track_idx).copied().unwrap_or(1.0);
        for (sample_idx, &sample) in track.iter().enumerate() {
            mixed[sample_idx] += sample * vol;
        }
    }

    // Soft-clip to prevent harsh digital clipping above 1.0/-1.0
    for sample in &mut mixed {
        if *sample > 1.0 {
            *sample = 1.0;
        } else if *sample < -1.0 {
            *sample = -1.0;
        }
    }

    mixed
}
