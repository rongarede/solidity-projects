import '@testing-library/jest-dom';

// Mock window.ethereum globally
declare global {
  interface Window {
    ethereum: any;
  }
}

// Global test setup
beforeEach(() => {
  // Reset window.ethereum for each test
  delete (window as any).ethereum;
  
  // Clear all timers
  jest.clearAllTimers();
  
  // Clear console methods if mocked
  if (jest.isMockFunction(console.error)) {
    (console.error as jest.MockedFunction<typeof console.error>).mockClear();
  }
  if (jest.isMockFunction(console.log)) {
    (console.log as jest.MockedFunction<typeof console.log>).mockClear();
  }
});

// Suppress console.error for expected errors in tests
const originalError = console.error;
beforeAll(() => {
  console.error = (...args: any[]) => {
    if (
      typeof args[0] === 'string' &&
      (args[0].includes('Warning: ReactDOM.render is deprecated') ||
       args[0].includes('Warning: validateDOMNesting'))
    ) {
      return;
    }
    originalError.call(console, ...args);
  };
});

afterAll(() => {
  console.error = originalError;
});