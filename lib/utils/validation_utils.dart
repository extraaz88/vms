class ValidationUtils {
  // Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  // Phone number validation
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your phone number';
    }

    // Remove all non-digit characters
    final cleanPhone = value.replaceAll(RegExp(r'[^\d]'), '');

    // Check if phone number has exactly 10 digits
    if (cleanPhone.length != 10) {
      return 'Phone number must be exactly 10 digits';
    }

    return null;
  }

  // Required field validation
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter $fieldName';
    }
    return null;
  }

  // Name validation
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your name';
    }

    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }

    if (value.trim().length > 50) {
      return 'Name cannot be more than 50 characters';
    }

    // Check for valid name characters (letters, spaces, hyphens, apostrophes)
    final nameRegex = RegExp(r"^[a-zA-Z\s\-']+$");
    if (!nameRegex.hasMatch(value.trim())) {
      return 'Name can only contain letters, spaces, hyphens, and apostrophes';
    }

    return null;
  }

  // Password validation
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }

    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }

    if (value.length > 50) {
      return 'Password cannot be more than 50 characters';
    }

    return null;
  }

  // Website URL validation
  static String? validateWebsite(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Website is optional
    }

    // Just check if it's not too long
    if (value.trim().length > 200) {
      return 'Website URL is too long';
    }

    return null;
  }

  // Amount validation
  static String? validateAmount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Amount is optional
    }

    final amount = double.tryParse(value.trim());
    if (amount == null) {
      return 'Please enter a valid amount';
    }

    if (amount < 0) {
      return 'Amount cannot be negative';
    }

    if (amount > 999999999) {
      return 'Amount cannot be more than 999,999,999';
    }

    return null;
  }

  // Postal code validation
  static String? validatePostalCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Postal code is optional
    }

    final postalCodeRegex = RegExp(r'^[0-9]{5,6}(-[0-9]{4})?$');
    if (!postalCodeRegex.hasMatch(value.trim())) {
      return 'Please enter a valid postal code';
    }

    return null;
  }

  // Company name validation
  static String? validateCompany(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Company is optional
    }

    if (value.trim().length < 2) {
      return 'Company name must be at least 2 characters';
    }

    if (value.trim().length > 100) {
      return 'Company name cannot be more than 100 characters';
    }

    return null;
  }

  // Title validation
  static String? validateTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Title is optional
    }

    if (value.trim().length < 2) {
      return 'Title must be at least 2 characters';
    }

    if (value.trim().length > 50) {
      return 'Title cannot be more than 50 characters';
    }

    return null;
  }

  // Address validation
  static String? validateAddress(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter an address';
    }

    if (value.trim().length < 5) {
      return 'Address must be at least 5 characters';
    }

    if (value.trim().length > 200) {
      return 'Address cannot be more than 200 characters';
    }

    return null;
  }

  // City validation
  static String? validateCity(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // City is optional
    }

    if (value.trim().length < 2) {
      return 'City name must be at least 2 characters';
    }

    if (value.trim().length > 50) {
      return 'City name cannot be more than 50 characters';
    }

    return null;
  }

  // State validation
  static String? validateState(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // State is optional
    }

    if (value.trim().length < 2) {
      return 'State name must be at least 2 characters';
    }

    if (value.trim().length > 50) {
      return 'State name cannot be more than 50 characters';
    }

    return null;
  }

  // Country validation
  static String? validateCountry(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Country is optional
    }

    if (value.trim().length < 2) {
      return 'Country name must be at least 2 characters';
    }

    if (value.trim().length > 50) {
      return 'Country name cannot be more than 50 characters';
    }

    return null;
  }

  // Description validation
  static String? validateDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Description is optional
    }

    if (value.trim().length < 10) {
      return 'Description must be at least 10 characters';
    }

    if (value.trim().length > 1000) {
      return 'Description cannot be more than 1000 characters';
    }

    return null;
  }

  // Campaign validation
  static String? validateCampaign(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Campaign is optional
    }

    if (value.trim().length < 2) {
      return 'Campaign name must be at least 2 characters';
    }

    if (value.trim().length > 100) {
      return 'Campaign name cannot be more than 100 characters';
    }

    return null;
  }

  // Notes validation for check-in/check-out
  static String? validateNotes(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Notes are optional
    }

    if (value.trim().length < 5) {
      return 'Notes must be at least 5 characters';
    }

    if (value.trim().length > 200) {
      return 'Notes cannot be more than 200 characters';
    }

    return null;
  }

  // Visit place validation
  static String? validateVisitPlace(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter visiting place';
    }

    if (value.trim().length < 2) {
      return 'Place name must be at least 2 characters';
    }

    if (value.trim().length > 100) {
      return 'Place name cannot be more than 100 characters';
    }

    return null;
  }

  // Visit person validation
  static String? validateVisitPerson(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter visiting person';
    }

    if (value.trim().length < 2) {
      return 'Person name must be at least 2 characters';
    }

    if (value.trim().length > 50) {
      return 'Person name cannot be more than 50 characters';
    }

    return null;
  }

  // Visit reason validation
  static String? validateVisitReason(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter visiting reason';
    }

    if (value.trim().length < 5) {
      return 'Reason must be at least 5 characters';
    }

    if (value.trim().length > 200) {
      return 'Reason cannot be more than 200 characters';
    }

    return null;
  }

  // Assigned user validation
  static String? validateAssignedUser(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Assigned user is optional
    }

    if (value.trim().length < 2) {
      return 'User name must be at least 2 characters';
    }

    if (value.trim().length > 50) {
      return 'User name cannot be more than 50 characters';
    }

    return null;
  }

  // Account validation
  static String? validateAccount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Account is optional
    }

    if (value.trim().length < 2) {
      return 'Account name must be at least 2 characters';
    }

    if (value.trim().length > 100) {
      return 'Account name cannot be more than 100 characters';
    }

    return null;
  }

  // Area validation
  static String? validateArea(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Area is optional
    }

    if (value.trim().length < 2) {
      return 'Area name must be at least 2 characters';
    }

    if (value.trim().length > 100) {
      return 'Area name cannot be more than 100 characters';
    }

    return null;
  }
}
