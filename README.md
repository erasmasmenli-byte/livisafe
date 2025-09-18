# Livisafe - Tokenized Livestock Vaccination System

## Overview

Livisafe is a blockchain-based system that provides proof of immunization for livestock animals. Built on the Stacks blockchain using Clarity smart contracts, Livisafe creates a tamper-proof, transparent, and traceable record of animal vaccinations for farmers, veterinarians, and agricultural authorities.

## Features

### Core Functionality
- **Vaccination Recording**: Register and track livestock vaccinations with immutable blockchain records
- **Animal Registration**: Maintain a registry of animals with unique identification
- **Vaccination Certificates**: Generate tokenized proof-of-vaccination certificates
- **Veterinarian Management**: Authorized veterinarian network for vaccine administration
- **Batch Vaccination Support**: Handle multiple animals in single vaccination events
- **Vaccination History**: Complete vaccination timeline for each animal
- **Certificate Verification**: Public verification of vaccination certificates

### Key Benefits
- **Transparency**: All vaccination records are publicly verifiable
- **Immutability**: Blockchain ensures records cannot be altered or falsified  
- **Traceability**: Complete audit trail from vaccination to certificate
- **Compliance**: Helps meet regulatory requirements for animal health
- **Trust**: Reduces fraud in livestock vaccination documentation
- **Efficiency**: Streamlines vaccination record management

## Smart Contracts

### 1. Livisafe Core Contract (`livisafe-core.clar`)
The main contract handling:
- Animal registration and management
- Vaccination record storage
- Certificate generation and validation
- Veterinarian authorization
- System administration

### 2. Vaccination Registry Contract (`vaccination-registry.clar`)
Supporting contract for:
- Vaccination history tracking
- Batch processing capabilities
- Vaccination status queries
- Certificate lifecycle management

## Technical Architecture

### Data Structures
- **Animals**: Unique ID, owner, species, age, registration date
- **Vaccinations**: Animal ID, vaccine type, date, veterinarian, batch info
- **Certificates**: Unique certificate ID, validation status, metadata
- **Veterinarians**: Authorized practitioners with credentials

### Key Functions
- `register-animal`: Register new animal in the system
- `record-vaccination`: Document vaccination administration
- `issue-certificate`: Generate vaccination certificate
- `verify-certificate`: Validate certificate authenticity
- `get-vaccination-history`: Retrieve animal's vaccination timeline

## Getting Started

### Prerequisites
- Clarinet CLI installed
- Node.js and npm
- Stacks wallet for testnet/mainnet deployment

### Installation
```bash
git clone https://github.com/erasmasmenli-byte/livisafe
cd livisafe
npm install
```

### Development
```bash
# Check contract syntax
clarinet check

# Run tests
npm test

# Console testing
clarinet console
```

### Testing
The project includes comprehensive tests covering:
- Animal registration workflows
- Vaccination recording processes
- Certificate generation and validation
- Error handling and edge cases
- Access control and authorization

## Use Cases

### For Farmers
- Register livestock animals
- Track vaccination schedules
- Generate certificates for market sales
- Prove compliance with health regulations

### For Veterinarians
- Record vaccination administrations
- Manage patient vaccination histories
- Issue digital certificates
- Maintain professional records

### For Authorities
- Verify vaccination compliance
- Audit livestock health records
- Investigate disease outbreaks
- Enforce health regulations

### For Markets/Buyers
- Verify animal health status
- Confirm vaccination certificates
- Ensure regulatory compliance
- Build consumer trust

## Roadmap

### Phase 1 (Current)
- ✅ Core smart contracts
- ✅ Basic vaccination recording
- ✅ Certificate generation

### Phase 2 (Future)
- Mobile app integration
- IoT device connectivity
- Advanced analytics
- Multi-chain support

### Phase 3 (Future)
- AI-powered health insights
- Supply chain integration
- Insurance partnerships
- Global standard compliance

## Contributing

We welcome contributions to Livisafe! Please see our contributing guidelines and submit pull requests for review.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions, please open an issue on GitHub or contact the development team.

---

**Livisafe - Securing Animal Health Through Blockchain Innovation** 🐄🔒
