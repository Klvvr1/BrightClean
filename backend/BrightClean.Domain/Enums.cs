namespace BrightClean.Domain.Enums
{
    public enum UserRole
    {
        Client,
        DeliveryStaff,
        LaundryAgent,
        Admin
    }

    public enum AccountStatus
    {
        PendingVerification,
        Active,
        Suspended,
        Deactivated
    }

    public enum Gender
    {
        Male,
        Female
    }

    public enum VehicleType
    {
        Car,
        Motorcycle,
        TukTuk
    }

    public enum DocumentType
    {
        NationalID,
        DriverLicense,
        VehicleImage,
        CommercialRegistration
    }

    public enum DocumentReviewStatus
    {
        Pending = 0,
        Approved = 1,
        Rejected = 2
    }

    public enum ServiceCategory
    {
        Laundry,
        HomeWovens,
        HomeServices,
        VehicleWash
    }

    public enum ServiceType
    {
        WashAndIron,
        DryClean,
        IronOnly,
        Curtains,
        Bedsheets,
        Blankets,
        Carpets,
        HomeCleaning,
        ACCleaning,
        WaterTankCleaning,
        SolarPanelCleaning,
        CarWash,
        MotorcycleWash
    }

    public enum PricingModel
    {
        PerItem,
        FlatFee
    }

    public enum DeliveryModel
    {
        TwoStage,
        TechnicianDispatch
    }

    public enum AgentServiceRequestedAction
    {
        None = 0,
        Activate = 1,
        Deactivate = 2
    }

    public enum BookingStatus
    {
        Draft,
        Pending,
        Accepted,
        InProgress,
        Ready,
        Completed,
        Cancelled
    }

    public enum TaskType
    {
        PickupFromClient,
        DeliveryToClient
    }

    public enum DeliveryTaskStatus
    {
        Unassigned,
        Assigned,
        InProgress,
        Completed
    }

    public enum PaymentMethod
    {
        CreditCard,
        Cash,
        Wallet,
        BankTransfer
    }

    public enum PaymentStatus
    {
        Pending = 0,
        Success = 1,
        Failed = 2,
        Refunded = 3,
        PendingReview = 4,
        Collected = 5
    }

    public enum OfferType
    {
        Percentage,
        FixedAmount
    }

    public enum OfferScope
    {
        AllAgents,
        SpecificAgent
    }
}
