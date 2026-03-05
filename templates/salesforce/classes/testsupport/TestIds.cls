/**
 * Generates unique suffixes for test data to avoid name collisions.
 * Use in builders to create unique names, emails, and external IDs.
 */
@IsTest
public class TestIds {

    private static Integer counter = 0;

    /**
     * Returns a short unique alphanumeric suffix.
     * Format: 5-character string combining timestamp and counter.
     */
    public static String nextSuffix() {
        counter++;
        Long timestamp = System.currentTimeMillis();
        String base = EncodingUtil.convertToHex(
            Blob.valueOf(String.valueOf(timestamp) + String.valueOf(counter))
        );
        return base.substring(0, 5).toUpperCase();
    }

    /**
     * Returns a unique email address for testing.
     */
    public static String nextEmail() {
        return 'test.' + nextSuffix() + '@example.test';
    }

    /**
     * Resets the counter. Use in @TestSetup if needed for deterministic IDs.
     */
    @TestVisible
    private static void reset() {
        counter = 0;
    }
}
