//$t@$h
/* cargo.toml
[package]
name = "video_to_text"
version = "0.1.0"
edition = "2018"

[dependencies]
reqwest = { version = "0.11", features = ["json"] }
tokio = { version = "1", features = ["full"] }
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"
base64 = "0.13"
*/
use reqwest::{Client, Error};
use serde::{Deserialize, Serialize};
use tokio;
use std::process::Command;
use tokio::time::{sleep, Duration};

#[derive(Debug, Serialize, Deserialize)]
struct TranscriptionResponse {
    name: String,
}

#[derive(Debug, Serialize, Deserialize)]
struct OperationStatusResponse {
    done: bool,
    response: Option<ResponseField>,
}

#[derive(Debug, Serialize, Deserialize)]
struct ResponseField {
    results: Vec<ResultField>,
}

#[derive(Debug, Serialize, Deserialize)]
struct ResultField {
    alternatives: Vec<AlternativeField>,
}

#[derive(Debug, Serialize, Deserialize)]
struct AlternativeField {
    transcript: String,
}

async fn extract_audio(video_path: &str, audio_path: &str) -> std::io::Result<()> {
    Command::new("ffmpeg")
        .args([
            "-i", video_path,
            "-acodec", "pcm_s16le",
            "-ar", "16000",
            "-ac", "1",
            audio_path,
        ])
        .output()?;
    Ok(())
}

#[tokio::main]
async fn main() -> Result<(), Error> {
    let api_key = "";
    let video_path = "";
    let audio_path = ""; // Path must be writable. Duh

    extract_audio(video_path, audio_path).await.expect("Failed to extract audio");

    let url = format!("https://speech.googleapis.com/v1p1beta1/speech:longrunningrecognize?key={}", api_key);
    let client = Client::new();

    let buffer = tokio::fs::read(audio_path).await.expect("Failed to read file");

    let request_body = serde_json::json!({
        "config": {
            "encoding": "LINEAR16",
            "sampleRateHertz": 16000,
            "languageCode": "en-US"
        },
        "audio": {
            "content": base64::encode(buffer)
        }
    });

    let response = client.post(&url)
        .json(&request_body)
        .send()
        .await?
        .json::<TranscriptionResponse>()
        .await?;

    let operation_name = response.name;

    let status_url = format!("https://speech.googleapis.com/v1/operations/{}?key={}", operation_name, api_key);
    let mut done = false;

    while !done {
        let status_response = client.get(&status_url)
            .send()
            .await?
            .json::<OperationStatusResponse>()
            .await?;

        done = status_response.done;

        if !done {
            sleep(Duration::from_secs(5)).await;
        }
    }

    // Result
    let final_response = client.get(&status_url)
        .send()
        .await?
        .json::<OperationStatusResponse>()
        .await?;

    if let Some(response) = final_response.response {
        for result in response.results {
            for alternative in result.alternatives {
                println!("Transcript: {}", alternative.transcript);
            }
        }
    }

    Ok(())
}
