/**
 * Generate TypeScript types from OpenAPI schema
 */
import fs from 'fs/promises';
import openapiTS from 'openapi-typescript';

const API_URL = process.env.API_BASE_URL || 'http://localhost:8000';
const OPENAPI_URL = `${API_URL}/openapi.json`;
const OUTPUT_FILE = 'src/lib/types.d.ts';

async function generateTypes() {
  try {
    console.log(`Fetching OpenAPI schema from ${OPENAPI_URL}...`);
    const output = await openapiTS(OPENAPI_URL);
    
    await fs.writeFile(OUTPUT_FILE, output);
    console.log(`✓ Generated types at ${OUTPUT_FILE}`);
  } catch (error) {
    console.error('Failed to generate types:', error);
    process.exit(1);
  }
}

generateTypes();
