using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using BrightClean.Domain.Enums;

namespace BrightClean.Domain.Entities
{
    public class UserDocument
    {
        [Key]
        public int DocumentID { get; set; }

        [Required]
        public int UserID { get; set; }

        [ForeignKey(nameof(UserID))]
        public virtual User User { get; set; } = null!;

        [Required]
        public DocumentType Type { get; set; }

        [Required]
        public string FileURL { get; set; } = string.Empty;

        [MaxLength(260)]
        public string? OriginalFileName { get; set; }

        [MaxLength(120)]
        public string? ContentType { get; set; }

        public long? FileSizeBytes { get; set; }

        [Required]
        public DateTime UploadedAt { get; set; } = DateTime.UtcNow;

        [Required]
        public DocumentReviewStatus ReviewStatus { get; set; } = DocumentReviewStatus.Pending;

        public DateTime? ReviewedAt { get; set; }

        public int? ReviewedByAdminID { get; set; }

        [ForeignKey(nameof(ReviewedByAdminID))]
        public virtual Admin? ReviewedByAdmin { get; set; }

        public string? ReviewNotes { get; set; }
    }
}
