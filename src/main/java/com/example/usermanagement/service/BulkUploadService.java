package com.example.usermanagement.service;

import com.example.usermanagement.model.User;
import org.apache.poi.ss.usermodel.*;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;

/**
 * Reads an uploaded file and converts each row into a User object.
 *
 * Expected format for ALL file types (CSV, TXT, XLSX): 4 columns, in this order:
 *   fullName, email, phoneNumber, address
 * The FIRST row is treated as a header and skipped.
 *
 * Example CSV/TXT row:
 *   fullName,email,phoneNumber,address
 *   Ravi Kumar,ravi@example.com,9998887777,Delhi India
 */
@Service
public class BulkUploadService {

    /**
     * Entry point: looks at the file's name/extension and picks the right parser.
     */
    public List<User> parseFile(MultipartFile file) throws IOException {
        String filename = file.getOriginalFilename();
        if (filename == null) {
            throw new IllegalArgumentException("File has no name.");
        }

        String lower = filename.toLowerCase();
        if (lower.endsWith(".csv") || lower.endsWith(".txt")) {
            return parseDelimitedText(file);
        } else if (lower.endsWith(".xlsx")) {
            return parseExcel(file);
        } else {
            throw new IllegalArgumentException("Unsupported file type. Please upload a .csv, .txt, or .xlsx file.");
        }
    }

    // ---------- CSV / TXT parsing (comma-separated) ----------
    private List<User> parseDelimitedText(MultipartFile file) throws IOException {
        List<User> users = new ArrayList<>();

        try (BufferedReader reader = new BufferedReader(
                new InputStreamReader(file.getInputStream(), StandardCharsets.UTF_8))) {

            String line;
            boolean firstLine = true;

            while ((line = reader.readLine()) != null) {
                if (line.isBlank()) continue; // skip empty lines

                if (firstLine) {
                    firstLine = false;
                    continue; // skip the header row
                }

                String[] parts = line.split(",", -1); // -1 keeps trailing empty fields
                users.add(buildUserFromParts(parts));
            }
        }

        return users;
    }

    // ---------- Excel (.xlsx) parsing using Apache POI ----------
    private List<User> parseExcel(MultipartFile file) throws IOException {
        List<User> users = new ArrayList<>();

        try (Workbook workbook = WorkbookFactory.create(file.getInputStream())) {
            Sheet sheet = workbook.getSheetAt(0); // first sheet in the file

            boolean firstRow = true;
            for (Row row : sheet) {
                if (firstRow) {
                    firstRow = false;
                    continue; // skip header row
                }
                if (row == null) continue;

                String[] parts = new String[4];
                for (int col = 0; col < 4; col++) {
                    Cell cell = row.getCell(col, Row.MissingCellPolicy.CREATE_NULL_AS_BLANK);
                    parts[col] = getCellValueAsString(cell);
                }

                // Skip fully blank rows (e.g. trailing empty rows in the sheet)
                if (parts[0].isBlank() && parts[1].isBlank()) continue;

                users.add(buildUserFromParts(parts));
            }
        }

        return users;
    }

    private String getCellValueAsString(Cell cell) {
        if (cell == null) return "";
        return switch (cell.getCellType()) {
            case STRING -> cell.getStringCellValue().trim();
            case NUMERIC -> String.valueOf((long) cell.getNumericCellValue()); // handles phone numbers stored as numbers
            case BOOLEAN -> String.valueOf(cell.getBooleanCellValue());
            default -> "";
        };
    }

    // ---------- Shared helper: turns a 4-column row into a User object ----------
    private User buildUserFromParts(String[] parts) {
        String fullName = parts.length > 0 ? parts[0].trim() : "";
        String email = parts.length > 1 ? parts[1].trim() : "";
        String phoneNumber = parts.length > 2 ? parts[2].trim() : "";
        String address = parts.length > 3 ? parts[3].trim() : "";

        return new User(fullName, email, phoneNumber, address);
    }
}
