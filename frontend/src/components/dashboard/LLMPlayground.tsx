'use client';

import React, { useState } from 'react';
import { Card } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { api } from '@/lib/api-client';

export function LLMPlayground() {
  const [prompt, setPrompt] = useState('');
  const [response, setResponse] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState('');
  
  const MAX_PROMPT_LENGTH = 10000;
  
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!prompt.trim()) return;
    
    setIsLoading(true);
    setError('');
    setResponse('');
    
    try {
      const data = await api.llm.complete({ prompt });
      setResponse(data.content);
    } catch (err: any) {
      if (err.status === 503) {
        setError('LLM service not configured. Set APP_ANTHROPIC_API_KEY to enable.');
      } else {
        setError('Unable to reach API. Is the server running?');
      }
    } finally {
      setIsLoading(false);
    }
  };
  
  const handleClear = () => {
    setPrompt('');
    setResponse('');
    setError('');
  };
  
  return (
    <Card title="🤖 AI Playground">
      <form onSubmit={handleSubmit} className="space-y-4">
        <div>
          <label htmlFor="prompt" className="block text-sm font-medium text-gray-700 mb-2">
            Your Prompt
          </label>
          <textarea
            id="prompt"
            value={prompt}
            onChange={(e) => setPrompt(e.target.value)}
            rows={5}
            maxLength={MAX_PROMPT_LENGTH}
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 resize-none"
            placeholder="Ask Claude anything..."
            disabled={isLoading}
          />
          <p className="mt-1 text-xs text-gray-500">
            {prompt.length} / {MAX_PROMPT_LENGTH} characters
          </p>
        </div>
        
        <div className="flex gap-2">
          <Button
            type="submit"
            variant="primary"
            loading={isLoading}
            disabled={isLoading || !prompt.trim()}
            className="flex-1"
          >
            {isLoading ? 'Thinking...' : 'Send'}
          </Button>
          <Button
            type="button"
            variant="secondary"
            onClick={handleClear}
            disabled={isLoading}
          >
            Clear
          </Button>
        </div>
        
        {error && (
          <div className="p-3 bg-yellow-50 border border-yellow-200 rounded-md">
            <p className="text-sm text-yellow-800">{error}</p>
          </div>
        )}
        
        {response && (
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              AI Response
            </label>
            <div className="p-4 bg-blue-50 border border-blue-200 rounded-md max-h-64 overflow-y-auto">
              <p className="text-sm text-gray-900 whitespace-pre-wrap leading-relaxed">{response}</p>
            </div>
          </div>
        )}
      </form>
    </Card>
  );
}
