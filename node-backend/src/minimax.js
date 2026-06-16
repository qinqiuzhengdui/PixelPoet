import axios from 'axios';

const API_KEY = process.env.MINIMAX_API_KEY || '';
const API_BASE = process.env.MINIMAX_API_BASE || 'https://api.minimaxi.com';
const MODEL = process.env.MINIMAX_MODEL || 'image-01';
const ASPECT_RATIO = process.env.MINIMAX_ASPECT_RATIO || '1:1';

const CARTOON_PORTRAIT_PROMPT = `STRICT IMAGE-TO-IMAGE: Cartoonize the uploaded reference ONLY — same person, same pose, same framing, same clothing colors. Do NOT generate a different face or a new random character. Do NOT change hairstyle layout, outfit design, or background color mood. Style transfer only: cute 2D chibi Q-version (large head, small body), super cute, extremely simplified details, flat saturated colors, bold outlines, no photorealism. 必须与参考图是同一人；禁止替换为无关新脸或新场景。保持原图发型与发色、服装款式与配色、背景氛围与构图。 无文字无水印。`;

export async function generateMoodImageBytes(userText) {
    if (!API_KEY) {
        throw new Error("MINIMAX_API_KEY not configured.");
    }
    
    let promptText = userText?.trim() || "平静与期待";
    let prompt = `Create a single striking artistic image that visually expresses the emotional mood and inner feeling described below. Style: expressive, atmospheric, symbolic — colors and composition should reflect the mood (joy, melancholy, tension, calm, etc.). No text, no letters, no watermark. Square composition, rich mood, suitable as emotional pixel art source. Author's words and mood to express: ${promptText}`;
    
    const body = {
        model: MODEL,
        prompt: prompt.substring(0, 1500),
        aspect_ratio: ASPECT_RATIO,
        response_format: "base64"
    };

    console.log(`[MiniMax] Generating mood image... promptLen=${body.prompt.length}`);
    return await postImageGeneration(body);
}

export async function generateCartoonFromPortrait(imageBase64, mimeType = 'image/jpeg') {
    if (!API_KEY) {
        throw new Error("MINIMAX_API_KEY not configured.");
    }
    const dataUrl = `data:${mimeType};base64,${imageBase64}`;
    
    const body = {
        model: MODEL,
        prompt: CARTOON_PORTRAIT_PROMPT.substring(0, 1500),
        aspect_ratio: ASPECT_RATIO,
        response_format: "base64",
        prompt_optimizer: false,
        subject_reference: [
            {
                type: "character",
                image_file: dataUrl
            }
        ]
    };

    console.log(`[MiniMax] Cartoonizing portrait...`);
    return await postImageGeneration(body);
}

async function postImageGeneration(body) {
    const url = `${API_BASE.replace(/\/$/, '')}/v1/image_generation`;
    try {
        const response = await axios.post(url, body, {
            headers: {
                'Authorization': `Bearer ${API_KEY}`,
                'Content-Type': 'application/json'
            },
            timeout: 180000 // 3 minutes
        });
        
        if (response.data?.base_resp?.status_code === 0) {
            const b64 = response.data.data?.image_base64?.[0];
            if (!b64) throw new Error("MiniMax returned empty image_base64");
            const cleanB64 = b64.replace(/^data:image\/\w+;base64,/, '');
            return Buffer.from(cleanB64, 'base64');
        } else {
            throw new Error(`MiniMax API Error: ${response.data?.base_resp?.status_msg}`);
        }
    } catch (error) {
        console.error("MiniMax Error:", error.response?.data || error.message);
        throw error;
    }
}
