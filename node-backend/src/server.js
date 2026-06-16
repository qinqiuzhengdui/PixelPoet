import express from 'express';
import cors from 'cors';
import { generateMoodImageBytes, generateCartoonFromPortrait } from './minimax.js';
import { processImageWasm } from './wasm_loader.js';

const app = express();
const port = process.env.PORT || 3000;

app.use(cors());
app.use(express.json({ limit: '20mb' }));

// 1. Text to Pixel Mood Image
app.post('/api/image/generate', async (req, res) => {
    try {
        const { text, blockSize = 8 } = req.body;
        console.log(`[API] /api/image/generate called with text: "${text}"`);
        
        // Step 1: Call MiniMax API
        const imageBytes = await generateMoodImageBytes(text);
        
        // Step 2: Pass to Moonbit WASM for pixelation and median cut quantization
        const { imageBuffer, palette, gridWidth, gridHeight } = await processImageWasm(imageBytes, blockSize);
        
        // Step 3: Return to frontend
        res.json({
            imageBase64: imageBuffer.toString('base64'),
            palette: palette,
            logicalWidth: gridWidth,
            logicalHeight: gridHeight
        });
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: err.message });
    }
});

// 2. Portrait to Cartoon Pixel Image
app.post('/api/image/cartoonize', async (req, res) => {
    try {
        const { imageBase64, mimeType, blockSize = 8 } = req.body;
        console.log(`[API] /api/image/cartoonize called.`);
        
        // Step 1: Call MiniMax API for Image-to-Image Cartoonization
        const generatedImageBytes = await generateCartoonFromPortrait(imageBase64, mimeType);
        
        // Step 2: Pass to Moonbit WASM for pixelation
        const { imageBuffer, palette, gridWidth, gridHeight } = await processImageWasm(generatedImageBytes, blockSize);
        
        // Step 3: Return
        res.json({
            imageBase64: imageBuffer.toString('base64'),
            palette: palette,
            logicalWidth: gridWidth,
            logicalHeight: gridHeight
        });
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: err.message });
    }
});

app.listen(port, () => {
    console.log(`Node.js + Moonbit server listening on port ${port}`);
    console.log(`Test server at http://localhost:${port}`);
});
