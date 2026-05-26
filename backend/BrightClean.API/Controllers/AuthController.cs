using System;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using System.Threading.Tasks;
using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;
using BrightClean.Infrastructure;
using BrightClean.Domain.Entities;
using BrightClean.Domain.Enums;
using BrightClean.API.DTOs;
using BCrypt.Net;

namespace BrightClean.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AuthController : ControllerBase
    {
        private readonly AppDbContext _context;
        private readonly IConfiguration _config;

        public AuthController(AppDbContext context, IConfiguration config)
        {
            _context = context;
            _config = config;
        }

        // POST: /api/auth/register/client
        [HttpPost("register/client")]
        public async Task<IActionResult> RegisterClient([FromBody] RegisterClientDto dto)
        {
            if (await _context.Users.AnyAsync(u => u.Email == dto.Email))
                return BadRequest(new { message = "البريد الإلكتروني مسجل بالفعل." });

            if (await _context.Users.AnyAsync(u => u.PhoneNo == dto.PhoneNo))
                return BadRequest(new { message = "رقم الهاتف مسجل بالفعل." });

            var client = new Client
            {
                FirstName = dto.FirstName,
                LastName = dto.LastName,
                Email = dto.Email,
                PasswordHash = BCrypt.Net.BCrypt.HashPassword(dto.Password),
                PhoneNo = dto.PhoneNo,
                DateOfBirth = dto.DateOfBirth,
                Gender = dto.Gender,
                AccountStatus = AccountStatus.Active,
                VerifiedAt = DateTime.UtcNow,
                IsApproved = true // Clients are auto-approved
            };

            _context.Clients.Add(client);
            await _context.SaveChangesAsync();

            return Ok(new { message = "تم تسجيل العميل بنجاح." });
        }

        // POST: /api/auth/register/agent
        [HttpPost("register/agent")]
        public async Task<IActionResult> RegisterAgent([FromForm] RegisterAgentDto dto, IFormFile commercialRegisterImage, IFormFile nationalIdImage)
        {
            if (await _context.Users.AnyAsync(u => u.Email == dto.Email))
                return BadRequest(new { message = "البريد الإلكتروني مسجل بالفعل." });

            if (await _context.Users.AnyAsync(u => u.PhoneNo == dto.PhoneNo))
                return BadRequest(new { message = "رقم الهاتف مسجل بالفعل." });

            if (await _context.LaundryAgents.AnyAsync(la => la.NationalIDNumber == dto.NationalIDNumber))
                return BadRequest(new { message = "الرقم المدني مسجل بالفعل." });

            if (await _context.LaundryAgents.AnyAsync(la => la.CommercialRegister == dto.CommercialRegister))
                return BadRequest(new { message = "السجل التجاري مسجل بالفعل." });

            if (commercialRegisterImage == null || commercialRegisterImage.Length == 0)
                return BadRequest(new { message = "صورة السجل التجاري مطلوبة." });

            if (nationalIdImage == null || nationalIdImage.Length == 0)
                return BadRequest(new { message = "صورة الهوية الوطنية مطلوبة." });

            // Ensure directory exists
            var uploadDir = System.IO.Path.Combine(System.IO.Directory.GetCurrentDirectory(), "wwwroot", "uploads");
            if (!System.IO.Directory.Exists(uploadDir))
            {
                System.IO.Directory.CreateDirectory(uploadDir);
            }

            // Save Commercial Register Image
            var crFileName = $"{Guid.NewGuid()}_{System.IO.Path.GetFileName(commercialRegisterImage.FileName)}";
            var crFilePath = System.IO.Path.Combine(uploadDir, crFileName);
            using (var stream = new System.IO.FileStream(crFilePath, System.IO.FileMode.Create))
            {
                await commercialRegisterImage.CopyToAsync(stream);
            }
            var crRelativeUrl = $"/uploads/{crFileName}";

            // Save National ID Image
            var idFileName = $"{Guid.NewGuid()}_{System.IO.Path.GetFileName(nationalIdImage.FileName)}";
            var idFilePath = System.IO.Path.Combine(uploadDir, idFileName);
            using (var stream = new System.IO.FileStream(idFilePath, System.IO.FileMode.Create))
            {
                await nationalIdImage.CopyToAsync(stream);
            }
            var idRelativeUrl = $"/uploads/{idFileName}";

            // Wrap DB inserts in a transaction
            using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                // Create agent address first
                var address = new Address
                {
                    Area = dto.Area,
                    Street = dto.Street,
                    Latitude = dto.Latitude,
                    Longitude = dto.Longitude
                };

                _context.Addresses.Add(address);
                await _context.SaveChangesAsync();

                var agent = new LaundryAgent
                {
                    FirstName = dto.FirstName,
                    LastName = dto.LastName,
                    Email = dto.Email,
                    PasswordHash = BCrypt.Net.BCrypt.HashPassword(dto.Password),
                    PhoneNo = dto.PhoneNo,
                    DateOfBirth = dto.DateOfBirth,
                    FatherName = dto.FatherName,
                    GrandfatherName = dto.GrandfatherName,
                    NationalIDNumber = dto.NationalIDNumber,
                    BusinessName = dto.BusinessName,
                    CommercialRegister = dto.CommercialRegister,
                    BankAcc = dto.BankAcc,
                    AddressID = address.AddressID,
                    AccountStatus = AccountStatus.PendingVerification,
                    IsApproved = false // Requires Admin approval
                };

                agent.Documents.Add(new UserDocument
                {
                    Type = DocumentType.CommercialRegistration,
                    FileURL = crRelativeUrl,
                    UploadedAt = DateTime.UtcNow
                });

                agent.Documents.Add(new UserDocument
                {
                    Type = DocumentType.NationalID,
                    FileURL = idRelativeUrl,
                    UploadedAt = DateTime.UtcNow
                });

                _context.LaundryAgents.Add(agent);
                await _context.SaveChangesAsync();

                await transaction.CommitAsync();

                return Ok(new { message = "تم تسجيل طلبك بنجاح، وهو قيد المراجعة حالياً." });
            }
            catch
            {
                await transaction.RollbackAsync();

                // Clean up uploaded files on transaction failure
                if (System.IO.File.Exists(crFilePath))
                {
                    System.IO.File.Delete(crFilePath);
                }
                if (System.IO.File.Exists(idFilePath))
                {
                    System.IO.File.Delete(idFilePath);
                }

                throw;
            }
        }

        // POST: /api/auth/register/driver
        [HttpPost("register/driver")]
        public async Task<IActionResult> RegisterDriver([FromBody] RegisterDriverDto dto)
        {
            if (await _context.Users.AnyAsync(u => u.Email == dto.Email))
                return BadRequest(new { message = "البريد الإلكتروني مسجل بالفعل." });

            if (await _context.Users.AnyAsync(u => u.PhoneNo == dto.PhoneNo))
                return BadRequest(new { message = "رقم الهاتف مسجل بالفعل." });

            if (await _context.DeliveryStaffs.AnyAsync(ds => ds.NationalIDNumber == dto.NationalIDNumber))
                return BadRequest(new { message = "الرقم المدني مسجل بالفعل." });

            if (await _context.DeliveryStaffs.AnyAsync(ds => ds.PlateNumber == dto.PlateNumber))
                return BadRequest(new { message = "رقم لوحة المركبة مسجل بالفعل." });

            var driver = new DeliveryStaff
            {
                FirstName = dto.FirstName,
                LastName = dto.LastName,
                Email = dto.Email,
                PasswordHash = BCrypt.Net.BCrypt.HashPassword(dto.Password),
                PhoneNo = dto.PhoneNo,
                DateOfBirth = dto.DateOfBirth,
                FatherName = dto.FatherName,
                GrandfatherName = dto.GrandfatherName,
                NationalIDNumber = dto.NationalIDNumber,
                VehicleType = dto.VehicleType,
                VehicleMake = dto.VehicleMake,
                VehicleModel = dto.VehicleModel,
                PlateNumber = dto.PlateNumber,
                BankAcc = dto.BankAcc,
                AccountStatus = AccountStatus.PendingVerification,
                IsApproved = false // Requires Admin approval
            };

            _context.DeliveryStaffs.Add(driver);
            await _context.SaveChangesAsync();

            return Ok(new { message = "تم تسجيل طلبك بنجاح، وهو قيد المراجعة حالياً." });
        }

        // POST: /api/auth/login
        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginDto dto)
        {
            var user = await _context.Users.FirstOrDefaultAsync(u => u.Email == dto.Email);
            if (user == null || !BCrypt.Net.BCrypt.Verify(dto.Password, user.PasswordHash))
            {
                return BadRequest(new { message = "البريد الإلكتروني أو كلمة المرور غير صحيحة." });
            }

            // If user is Agent or Driver, check if IsApproved == true
            if (user.Role == UserRole.LaundryAgent || user.Role == UserRole.DeliveryStaff)
            {
                if (!user.IsApproved)
                {
                    return StatusCode(StatusCodes.Status403Forbidden, new { message = "حسابك قيد المراجعة من قبل الإدارة" });
                }
            }

            // Generate JWT
            var token = GenerateJwtToken(user);

            return Ok(new
            {
                token = token,
                userId = user.UserID,
                email = user.Email,
                role = user.Role.ToString(),
                firstName = user.FirstName,
                lastName = user.LastName,
                phoneNo = user.PhoneNo
            });
        }

        private string GenerateJwtToken(User user)
        {
            var claims = new[]
            {
                new Claim(JwtRegisteredClaimNames.Sub, user.UserID.ToString()),
                new Claim(ClaimTypes.NameIdentifier, user.UserID.ToString()),
                new Claim(JwtRegisteredClaimNames.Email, user.Email),
                new Claim(ClaimTypes.Role, user.Role.ToString())
            };

            var secretKey = _config["Jwt:Key"];
            if (string.IsNullOrEmpty(secretKey))
            {
                throw new InvalidOperationException("JWT signing key is not configured. Set Jwt:Key in user secrets or environment variables.");
            }
            var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secretKey));
            var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

            var issuer = _config["Jwt:Issuer"] ?? "BrightCleanBackend";
            var audience = _config["Jwt:Audience"] ?? "BrightCleanClients";
            var expireDays = Convert.ToInt32(_config["Jwt:ExpireDays"] ?? "7");

            var token = new JwtSecurityToken(
                issuer: issuer,
                audience: audience,
                claims: claims,
                expires: DateTime.UtcNow.AddDays(expireDays),
                signingCredentials: creds
            );

            return new JwtSecurityTokenHandler().WriteToken(token);
        }

        private static readonly System.Collections.Concurrent.ConcurrentDictionary<string, (string Token, DateTime Expires)> _resetTokens = new();

        // POST: /api/auth/forgot-password
        [HttpPost("forgot-password")]
        public async Task<IActionResult> ForgotPassword([FromBody] ForgotPasswordDto dto)
        {
            var user = await _context.Users.FirstOrDefaultAsync(u => u.Email == dto.Email);

            // Always return the same generic message regardless of whether user exists
            if (user != null)
            {
                // Generate a 6-digit OTP code using cryptographically secure RNG
                var otp = System.Security.Cryptography.RandomNumberGenerator.GetInt32(100000, 1000000).ToString();

                // Store it with a 15-minute expiry
                _resetTokens[dto.Email] = (otp, DateTime.UtcNow.AddMinutes(15));

                // Stub email sending: log to console (without OTP value)
                Console.WriteLine($"Password reset OTP generated for {dto.Email}");

                // In debug/development, include OTP in response for testing
                #if DEBUG
                return Ok(new {
                    message = "إذا كان الحساب موجوداً، سوف تستلم تعليمات إعادة تعيين كلمة المرور.",
                    otp = otp // Only in debug builds
                });
                #endif
            }

            // Return generic message (no user existence information leaked)
            return Ok(new {
                message = "إذا كان الحساب موجوداً، سوف تستلم تعليمات إعادة تعيين كلمة المرور."
            });
        }

        // POST: /api/auth/reset-password
        [HttpPost("reset-password")]
        public async Task<IActionResult> ResetPassword([FromBody] ResetPasswordDto dto)
        {
            var user = await _context.Users.FirstOrDefaultAsync(u => u.Email == dto.Email);

            // Generic message for invalid token/expired token/missing user
            if (user == null || !_resetTokens.TryGetValue(dto.Email, out var tokenData) || tokenData.Token != dto.Token)
            {
                return BadRequest(new { message = "رمز التحقق غير صحيح أو منتهي الصلاحية." });
            }

            if (DateTime.UtcNow > tokenData.Expires)
            {
                _resetTokens.TryRemove(dto.Email, out _);
                return BadRequest(new { message = "رمز التحقق غير صحيح أو منتهي الصلاحية." });
            }

            // Valid! Reset password
            user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(dto.NewPassword);
            await _context.SaveChangesAsync();

            // Clear token
            _resetTokens.TryRemove(dto.Email, out _);

            return Ok(new { message = "تم إعادة تعيين كلمة المرور بنجاح." });
        }
    }

    public class ForgotPasswordDto
    {
        [Required]
        [EmailAddress]
        public string Email { get; set; } = string.Empty;
    }

    public class ResetPasswordDto
    {
        [Required]
        [EmailAddress]
        public string Email { get; set; } = string.Empty;

        [Required]
        public string Token { get; set; } = string.Empty;

        [Required]
        [MinLength(6, ErrorMessage = "Password must be at least 6 characters.")]
        public string NewPassword { get; set; } = string.Empty;
    }
}
