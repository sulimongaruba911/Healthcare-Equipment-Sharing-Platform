import { describe, it, expect, beforeEach } from 'vitest';
import { mockClarityBitcoin, mockClarityBlockInfo } from './helpers/clarity-mocks';

// Mock the Clarity environment
const mockClarity = {
  tx: {
    sender: 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5',
  },
  contracts: {
    'device-registration': {
      functions: {
        'register-device': jest.fn(),
        'update-device-status': jest.fn(),
        'update-device-location': jest.fn(),
        'get-device': jest.fn(),
        'is-device-available': jest.fn(),
      }
    }
  }
};

describe('Device Registration Contract', () => {
  beforeEach(() => {
    // Reset mocks
    Object.values(mockClarity.contracts['device-registration'].functions).forEach(fn => fn.mockReset());
    
    // Set up default responses
    mockClarity.contracts['device-registration'].functions['register-device'].mockReturnValue({ value: 1 });
    mockClarity.contracts['device-registration'].functions['get-device'].mockReturnValue({
      value: {
        name: 'Portable Ultrasound',
        'device-type': 'Ultrasound',
        manufacturer: 'MedTech Inc',
        model: 'PT-2000',
        'serial-number': 'SN12345',
        'acquisition-date': 1620000000,
        status: 1,
        'current-location': mockClarity.tx.sender,
        owner: mockClarity.tx.sender
      }
    });
    mockClarity.contracts['device-registration'].functions['is-device-available'].mockReturnValue({ value: true });
  });
  
  it('should register a new device', async () => {
    const result = await mockClarity.contracts['device-registration'].functions['register-device'](
        'Portable Ultrasound',
        'Ultrasound',
        'MedTech Inc',
        'PT-2000',
        'SN12345',
        1620000000
    );
    
    expect(result.value).toBe(1);
    expect(mockClarity.contracts['device-registration'].functions['register-device']).toHaveBeenCalledTimes(1);
  });
  
  it('should retrieve device details', async () => {
    const result = await mockClarity.contracts['device-registration'].functions['get-device'](1);
    
    expect(result.value).toEqual({
      name: 'Portable Ultrasound',
      'device-type': 'Ultrasound',
      manufacturer: 'MedTech Inc',
      model: 'PT-2000',
      'serial-number': 'SN12345',
      'acquisition-date': 1620000000,
      status: 1,
      'current-location': mockClarity.tx.sender,
      owner: mockClarity.tx.sender
    });
  });
  
  it('should update device status', async () => {
    mockClarity.contracts['device-registration'].functions['update-device-status'].mockReturnValue({ value: true });
    
    const result = await mockClarity.contracts['device-registration'].functions['update-device-status'](1, 2);
    
    expect(result.value).toBe(true);
    expect(mockClarity.contracts['device-registration'].functions['update-device-status']).toHaveBeenCalledWith(1, 2);
  });
  
  it('should check if device is available', async () => {
    const result = await mockClarity.contracts['device-registration'].functions['is-device-available'](1);
    
    expect(result.value).toBe(true);
  });
});
