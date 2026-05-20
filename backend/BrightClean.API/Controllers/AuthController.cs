using System;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using System.Threading.Tasks;
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
        public async Task<IActionResult> RegisterAgent([FromBody] RegisterAgentDto dto)
        {
            if (await _context.Users.AnyAsync(u => u.Email == dto.Email))
                return BadRequest(new { message = "البريد الإلكتروني مسجل بالفعل." });

            if (await _context.Users.AnyAsync(u => u.PhoneNo == dto.PhoneNo))
                return BadRequest(new { message = "رقم الهاتف مسجل بالفعل." });

            if (await _context.LaundryAgents.AnyAsync(la => la.NationalIDNumber == dto.NationalIDNumber))
                return BadRequest(new { message = "الرقم المدني مسجل بالفعل." });

            if (await _context.LaundryAgents.AnyAsync(la => la.CommercialRegister == dto.CommercialRegister))
                return BadRequest(new { message = "السجل التجاري مسجل بالفعل." });

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

            _context.LaundryAgents.Add(agent);
            await _context.SaveChangesAsync();

            return Ok(new { message = "تم تسجيل طلبك بنجاح، وهو قيد المراجعة حالياً." });
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
                lastName = user.LastName
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

            var secretKey = _config["Jwt:Key"] ?? "AVerySecureLongSecretKeyThatHasAtLeast256BitsOfLength";
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
    }
}
